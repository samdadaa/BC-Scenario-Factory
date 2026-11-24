namespace BCScenarioFactory.CRM;

using BCScenarioFactory.Core;
using BCScenarioFactory.DataGeneration;
using BCScenarioFactory.Lifecycle;
using BCScenarioFactory.ScenarioManagement;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

/// <summary>
/// CRM relationships for standard-posted sales invoices of the same run, in the approved follow-up stage (module CRM).
/// Per invoice (about 35 %) an opportunity is created for the contact that belongs to the invoice customer through the
/// standard business relation; one campaign per run bundles these opportunities. Existing contacts, campaigns and
/// sales cycles are never changed. Cases without a usable contact, sales cycle or number series are skipped before any write (SOURCE).
/// </summary>
codeunit 90487 "BCSF CRM Processor"
{
  Access = Internal;

  procedure CycleCode(): Code[10]
  begin
    exit('BCSF');
  end;

  /// <summary>Additive marker: CRM is offered only when number series for campaigns and opportunities and a usable sales cycle exist.</summary>
  procedure AddSettings(var Settings: JsonObject)
  var
    Marketing: Record "Marketing Setup";
  begin
    if not Marketing.Get() then
      exit;
    if (Marketing."Campaign Nos." = '') or (Marketing."Opportunity Nos." = '') or (SalesCycle() = '') then
      exit;
    Settings.Add('crmVersion', 1);
    // Additive: new captures also create a segment of the opportunity contacts and a follow-up task per opportunity.
    if (Marketing."Segment Nos." <> '') and (Marketing."To-do Nos." <> '') then
      Settings.Add('crmExtVersion', 1);
  end;

  procedure Enabled(Context: JsonObject): Boolean
  var
    Selection: Codeunit "BCSF Module Selection";
  begin
    exit(Selection.MarkerEnabled(Context, 'crmVersion'));
  end;

  /// <summary>Additive foundation: a dedicated sales cycle with one stage. Existing sales cycles stay unchanged.</summary>
  [CommitBehavior(CommitBehavior::Error)]
  procedure PrepareFoundation()
  var
    Cycle: Record "Sales Cycle";
    Stage: Record "Sales Cycle Stage";
    Guard: Codeunit "BCSF Environment Guard";
  begin
    Guard.EnsureCanConfigure(CompanyName());
    // Optional stage: without write permission CRM is simply not offered.
    if not Cycle.WritePermission() or not Stage.WritePermission() then
      exit;
    if not Cycle.Get(CycleCode()) then begin
      Cycle.Init();
      Cycle.Code := CycleCode();
      Cycle.Description := CopyStr(CycleLbl, 1, MaxStrLen(Cycle.Description));
      Cycle.Insert(true);
    end;
    if not Stage.Get(CycleCode(), 1) then begin
      Stage.Init();
      Stage."Sales Cycle Code" := CycleCode();
      Stage.Stage := 1;
      Stage.Description := CopyStr(StageLbl, 1, MaxStrLen(Stage.Description));
      Stage."Completed %" := 10;
      Stage."Chances of Success %" := 20;
      Stage.Insert(true);
    end;
  end;

  /// <summary>Usable sales cycle: the Scenario Factory cycle first, else an unblocked existing one with a stage.</summary>
  local procedure SalesCycle(): Code[10]
  var
    Cycle: Record "Sales Cycle";
    Stage: Record "Sales Cycle Stage";
  begin
    if Cycle.Get(CycleCode()) and not Cycle.Blocked then begin
      Stage.SetRange("Sales Cycle Code", Cycle.Code);
      if not Stage.IsEmpty() then
        exit(Cycle.Code);
    end;
    exit('');
  end;

  /// <summary>Deterministic: 0 no CRM follow-up for this invoice, 1 opportunity (35 %).</summary>
  procedure PlanKind(Context: JsonObject; NodeCode: Code[30]; LogicalKey: Integer): Integer
  var
    Seed: Codeunit "BCSF Seed Engine";
  begin
    if Seed.SampleInteger(Context, NodeCode, Format(LogicalKey, 0, 9), 'CRM-PLAN', 1, 100) <= 35 then
      exit(1);
    exit(0);
  end;

  procedure CampaignDescription(RunId: Guid): Text[100]
  begin
    exit(CopyStr(StrSubstNo(CampaignLbl, CopyStr(Format(RunId, 0, 4), 1, 8)), 1, 100));
  end;

  /// <summary>Contact of the customer through the standard business relation; empty when none is usable.</summary>
  procedure ContactFor(CustomerNo: Code[20]): Code[20]
  var
    Relation: Record "Contact Business Relation";
    Contact: Record Contact;
  begin
    Relation.SetRange("Link to Table", Relation."Link to Table"::Customer);
    Relation.SetRange("No.", CustomerNo);
    if not Relation.FindFirst() then
      exit('');
    if not Contact.Get(Relation."Contact No.") then
      exit('');
    if Contact.Type <> Contact.Type::Company then
      exit('');
    exit(Contact."No.");
  end;

  [CommitBehavior(CommitBehavior::Error)]
  procedure RunForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; Invoice: Record "Sales Invoice Header"; ParentId: Guid)
  var
    Customer: Record Customer;
    Campaign: Record Campaign;
    Opportunity: Record Opportunity;
    Registry: Codeunit "BCSF Record Registry";
    Selection: Codeunit "BCSF Module Selection";
    ContactNo: Code[20];
    CycleNo: Code[10];
    SkipReason: Code[30];
    Description: Text[100];
  begin
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then
      exit;
    CycleNo := SalesCycle();
    if CycleNo <> '' then
      ContactNo := ContactFor(Invoice."Bill-to Customer No.");
    if (CycleNo = '') or (ContactNo = '') or not Customer.Get(Invoice."Bill-to Customer No.") or
      not Campaign.WritePermission() or not Opportunity.WritePermission()
    then
      SkipReason := 'SOURCE';
    if SkipReason = '' then begin
      Description := CampaignDescription(RunId);
      Campaign.SetRange(Description, Description);
      if not Campaign.FindFirst() then begin
        Campaign.Init();
        Campaign.Description := Description;
        Campaign."Starting Date" := Invoice."Posting Date";
        Campaign."Ending Date" := Invoice."Posting Date" + 30;
        Campaign.Insert(true);
        Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CRM-CAMPAIGN', BatchId, Campaign.RecordId(), ParentId);
      end;
      Opportunity.Init();
      Opportunity.Validate("Contact No.", ContactNo);
      Opportunity.Validate("Sales Cycle Code", CycleNo);
      Opportunity.Validate("Campaign No.", Campaign."No.");
      Opportunity.Description := CopyStr(StrSubstNo(OpportunityLbl, Invoice."No."), 1, MaxStrLen(Opportunity.Description));
      Opportunity."Creation Date" := Invoice."Posting Date";
      Opportunity.Insert(true);
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CRM-OPPORTUNITY', BatchId, Opportunity.RecordId(), ParentId);
      if Selection.MarkerEnabled(Context, 'crmExtVersion') then
        CreateExtension(RunId, NodeCode, LogicalKey, BatchId, ParentId, Invoice, Customer, ContactNo, Campaign."No.", Opportunity."No.");
    end else
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CRM-SKIP', BatchId, Invoice.RecordId(), ParentId, SkipReason);
  end;

  procedure SegmentDescription(RunId: Guid): Text[100]
  begin
    exit(CopyStr(StrSubstNo(SegmentLbl, CopyStr(Format(RunId, 0, 4), 1, 8)), 1, 100));
  end;

  /// <summary>One segment per run with a line for every opportunity contact, and a follow-up task when the customer has a salesperson.</summary>
  local procedure CreateExtension(RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; BatchId: Guid; ParentId: Guid; Invoice: Record "Sales Invoice Header"; Customer: Record Customer; ContactNo: Code[20]; CampaignNo: Code[20]; OpportunityNo: Code[20])
  var
    Segment: Record "Segment Header";
    SegmentLine: Record "Segment Line";
    FollowUp: Record "To-do";
    Salesperson: Record "Salesperson/Purchaser";
    Registry: Codeunit "BCSF Record Registry";
    Description: Text[100];
    LineNo: Integer;
  begin
    if not Segment.WritePermission() or not SegmentLine.WritePermission() then
      exit;
    Description := SegmentDescription(RunId);
    Segment.SetRange(Description, Description);
    if not Segment.FindFirst() then begin
      Segment.Init();
      Segment.Description := Description;
      Segment.Date := Invoice."Posting Date";
      Segment.Insert(true);
      Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CRM-SEGMENT', BatchId, Segment.RecordId(), ParentId);
    end;
    SegmentLine.SetRange("Segment No.", Segment."No.");
    SegmentLine.SetRange("Contact No.", ContactNo);
    if SegmentLine.IsEmpty() then begin
      SegmentLine.Reset();
      SegmentLine.SetRange("Segment No.", Segment."No.");
      LineNo := 10000;
      if SegmentLine.FindLast() then
        LineNo := SegmentLine."Line No." + 10000;
      SegmentLine.Init();
      SegmentLine."Segment No." := Segment."No.";
      SegmentLine."Line No." := LineNo;
      SegmentLine.Validate("Contact No.", ContactNo);
      SegmentLine.Insert(true);
    end;
    if (Customer."Salesperson Code" = '') or not Salesperson.Get(Customer."Salesperson Code") or not FollowUp.WritePermission() then
      exit;
    FollowUp.Init();
    FollowUp.Type := FollowUp.Type::"Phone Call";
    FollowUp.Description := CopyStr(StrSubstNo(TaskLbl, Invoice."No."), 1, MaxStrLen(FollowUp.Description));
    FollowUp.Validate("Contact No.", ContactNo);
    FollowUp.Validate("Salesperson Code", Customer."Salesperson Code");
    FollowUp.Validate("Campaign No.", CampaignNo);
    FollowUp.Validate("Opportunity No.", OpportunityNo);
    FollowUp.Date := Invoice."Posting Date" + 7;
    FollowUp.Insert(true);
    Registry.RegisterResult(RunId, NodeCode, LogicalKey, 'CRM-TASK', BatchId, FollowUp.RecordId(), ParentId);
  end;

  /// <summary>Read-only validation: the opportunity belongs to the contact of the invoice customer and to the run campaign.</summary>
  procedure ValidateForSalesInvoice(Context: JsonObject; RunId: Guid; NodeCode: Code[30]; LogicalKey: Integer; Invoice: Record "Sales Invoice Header")
  var
    Entry: Record "BCSF Generated Record";
    Opportunity: Record Opportunity;
    Campaign: Record Campaign;
    FollowUp: Record "To-do";
  begin
    Entry.SetRange("Run Id", RunId);
    Entry.SetRange("Node Code", NodeCode);
    Entry.SetRange("Logical Key", LogicalKey);
    Entry.SetFilter("Artifact Code", 'CRM*');
    if PlanKind(Context, NodeCode, LogicalKey) = 0 then begin
      if not Entry.IsEmpty() then
        Error(ResultErr);
      exit;
    end;
    if Entry.IsEmpty() then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'CRM-SKIP');
    if Entry.FindFirst() then begin
      Entry.TestField("Posting Skipped", true);
      Entry.TestField("Table Id", Database::"Sales Invoice Header");
      if Entry."Skip Reason Code" <> 'SOURCE' then
        Error(ResultErr);
      exit;
    end;
    Entry.SetRange("Artifact Code", 'CRM-OPPORTUNITY');
    Entry.FindFirst();
    Entry.TestField("Table Id", Database::Opportunity);
    Opportunity.GetBySystemId(Entry."Record SystemId");
    if Opportunity."Contact Company No." <> ContactFor(Invoice."Bill-to Customer No.") then
      Error(ResultErr);
    if Opportunity."Campaign No." = '' then
      Error(ResultErr);
    Campaign.Get(Opportunity."Campaign No.");
    if Campaign.Description <> CampaignDescription(RunId) then
      Error(ResultErr);
    Entry.SetRange("Artifact Code", 'CRM-TASK');
    if Entry.FindFirst() then begin
      Entry.TestField("Table Id", Database::"To-do");
      FollowUp.GetBySystemId(Entry."Record SystemId");
      FollowUp.TestField("Opportunity No.", Opportunity."No.");
      FollowUp.TestField("Contact No.", Opportunity."Contact No.");
    end;
  end;

  var
    CycleLbl: Label 'Scenario Factory sales cycle';
    StageLbl: Label 'Qualification';
    SegmentLbl: Label 'Scenario Factory segment %1', Comment = '%1 = short run id';
    TaskLbl: Label 'Follow up on invoice %1', Comment = '%1 = posted sales invoice number';
    CampaignLbl: Label 'Scenario Factory campaign %1', Comment = '%1 = short run id';
    OpportunityLbl: Label 'Follow-up opportunity for invoice %1', Comment = '%1 = posted sales invoice number';
    ResultErr: Label 'CRM results are missing, changed or not verifiable. Keep the batch blocked for review; do not repeat an uncertain step.';
}
