namespace BCScenarioFactory.ScenarioManagement;

page 90132 "BCSF Scenario Wizard"
{
  ApplicationArea = All;
  Caption = 'Plan a Scenario';
  PageType = NavigatePage;
  SourceTable = "BCSF Scenario";
  InsertAllowed = false;
  DeleteAllowed = false;
  layout
  {
    area(Content)
    {
      group(Industry)
      {
        Caption = '1. Industry and Purpose';
        Visible = StepNo = 1;
        Editable = not Captured;
        field(Description; Rec.Description) { }
        field("Profile Code"; Rec."Profile Code") { }
        field("Profile Version"; Rec."Profile Version") { }
        field("Usage Mode"; Rec."Usage Mode") { }
        field(ProfileNotice; ProfileNoticeLbl)
        {
          Caption = 'Profile Availability';
          ToolTip = 'Explains that profile identifiers do not install generators or apply an industry preset.';
          Editable = false;
          MultiLine = true;
        }
      }
      group(ModuleSelection)
      {
        Caption = '2. Modules';
        Visible = StepNo = 2;
        Editable = not Captured;
        part(Modules; "BCSF Scenario Modules")
        {
          SubPageLink = "Scenario Id" = field("Scenario Id");
          UpdatePropagation = Both;
        }
        field(DependencyNotice; DependencyNoticeLbl)
        {
          Caption = 'Dependencies';
          ToolTip = 'Explains the existing dependency rules. The frozen plan shows concrete blockers in the final step.';
          MultiLine = true;
          Editable = false;
        }
      }
      group(TargetSelection)
      {
        Caption = '3. Entity Targets and Rules';
        Visible = StepNo = 3;
        Editable = not Captured;
        field(Seed; Rec.Seed) { }
        field("Starting Date"; Rec."Starting Date") { }
        field("Ending Date"; Rec."Ending Date") { }
        field("Data Language"; Rec."Data Language") { }
        field("Batch Size"; Rec."Batch Size") { }
        field(TargetNotice; TargetNoticeLbl)
        {
          Caption = 'Target Editing';
          ToolTip = 'Explains how to configure document targets within the maximum process scope.';
          MultiLine = true;
          Editable = false;
        }
        part(Targets; "BCSF Data Targets")
        {
          SubPageLink = "Scenario Id" = field("Scenario Id");
          UpdatePropagation = Both;
        }
      }
      group(ProcessScope)
      {
        Caption = '4. Process Scope';
        Visible = StepNo = 4;
        Editable = not Captured;
        field("Process Mode"; Rec."Process Mode") { }
        field(PostingNotice; PostingNoticeLbl)
        {
          Caption = 'Posting and Follow-up Risks';
          ToolTip = 'Explains that posting is currently blocked by the execution contract and is never approved by selecting a process mode.';
          MultiLine = true;
          Editable = false;
        }
      }
      group(Review)
      {
        Caption = '5. Preflight, Approval and Scheduling';
        Visible = StepNo = 5;
        field(CapturedRunId; CapturedRunId)
        {
          Caption = 'Captured Run ID';
          ToolTip = 'Shows the immutable run captured for this wizard. Capture explicitly before reviewing or scheduling.';
          Editable = false;
        }
        field(ReviewNotice; ReviewNoticeLbl)
        {
          Caption = 'Review Instructions';
          ToolTip = 'Explains the required snapshot, dependency and setup checks before approval.';
          MultiLine = true;
          Editable = false;
        }
      }
    }
  }
  actions
  {
    area(Processing)
    {
      action(Back)
      {
        Caption = 'Back';
        ToolTip = 'Returns to the previous configuration step before capture.';
        Image = PreviousRecord;
        InFooterBar = true;
        Enabled = (StepNo > 1) and not Captured;
        trigger OnAction()
        begin
          CurrPage.SaveRecord();
          StepNo -= 1;
          CurrPage.Update(false);
        end;
      }
      action(Next)
      {
        Caption = 'Next';
        ToolTip = 'Saves the template and continues to the next step without starting work.';
        Image = NextRecord;
        InFooterBar = true;
        Enabled = StepNo < 5;
        trigger OnAction()
        begin
          CurrPage.SaveRecord();
          StepNo += 1;
          CurrPage.Update(false);
        end;
      }
      action(Capture)
      {
        Caption = 'Capture for Review';
        ToolTip = 'Creates one immutable run from the current template. Locks this wizard configuration; no queue work starts.';
        Image = Archive;
        InFooterBar = true;
        Enabled = (StepNo = 5) and not Captured;
        trigger OnAction()
        var
          Writer: Codeunit "BCSF Snapshot Writer";
        begin
          CurrPage.SaveRecord();
          CapturedRunId := Writer.CreateSnapshot(Rec."Scenario Id");
          Captured := true;
          CurrPage.Update(false);
        end;
      }
      action(OpenRun)
      {
        Caption = 'Open Captured Run';
        ToolTip = 'Opens the captured configuration and existing planning, preflight, execution and monitoring actions.';
        Image = View;
        InFooterBar = true;
        Enabled = Captured;
        trigger OnAction()
        var
          Header: Record "BCSF Run Header";
        begin
          Header.Get(CapturedRunId);
          Page.Run(Page::"BCSF Run Card", Header);
        end;
      }
      action(CloseWizard)
      {
        Caption = 'Close';
        ToolTip = 'Closes the wizard. Saved template edits and any captured run remain available; closing does not schedule work.';
        Image = Close;
        InFooterBar = true;
        trigger OnAction()
        begin
          CurrPage.Close();
        end;
      }
    }
  }
  trigger OnOpenPage()
  begin
    Rec.TestField("Scenario Id");
    StepNo := 1;
  end;

  procedure GetCapturedRunId(): Guid
  begin
    if not Captured then
      Error(CaptureFirstErr);
    exit(CapturedRunId);
  end;

  procedure IsReviewStep(): Boolean
  begin
    exit((StepNo = 5) and Captured);
  end;

  var
    CapturedRunId: Guid;
    StepNo: Integer;
    Captured: Boolean;
    ProfileNoticeLbl: Label 'Enter the intended industry profile code and version. Full industry presets and real generators are not available yet; these identifiers describe planning intent only.';
    DependencyNoticeLbl: Label 'Finance setup is required for master data. Sales documents require customer and item references; purchases require vendor and item references. Posted sales may require stock. No missing quantities or setup are added automatically.';
    TargetNoticeLbl: Label 'Enable modules first. Each entity has its own quantity, mode and shares. To add documents above the current maximum, visit step 4, raise the scope, then return here. Adjust targets before lowering the maximum.';
    PostingNoticeLbl: Label 'Posted movements and follow-up processes require separate authorization and valid standard posting setup. The current worker does not approve posting. Selecting a mode never authorizes posting or changes setup.';
    ReviewNoticeLbl: Label 'Capture the template, review the dependency plan and current setup preflight, then request scheduling explicitly. Blockers prevent preparation and start. After capture, changes require a new wizard/run. Closing retains saved configuration.';
    CaptureFirstErr: Label 'Capture a run in the final wizard step before reviewing or scheduling it.';
}
