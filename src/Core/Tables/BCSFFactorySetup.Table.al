namespace BCScenarioFactory.Core;

table 90100 "BCSF Factory Setup"
{
  Access = Internal;
  Caption = 'Scenario Factory Setup';
  DataClassification = SystemMetadata;
  DataPerCompany = true;

  fields
  {
    field(1; "Primary Key"; Code[10])
    {
      Caption = 'Primary Key';
      Editable = false;
    }
    field(2; "Generation Enabled"; Boolean)
    {
      Caption = 'Generation Enabled';
      ToolTip = 'Specifies whether generation is explicitly allowed in the configured sandbox and company. Disabled by default.';
    }
    field(3; "Allowed Environment Name"; Text[80])
    {
      Caption = 'Allowed Environment Name';
      ToolTip = 'Specifies the exact sandbox environment name permitted for this setup. A name never overrides the sandbox type check.';
    }
    field(4; "Allowed Company Name"; Text[30])
    {
      Caption = 'Allowed Company Name';
      DataClassification = OrganizationIdentifiableInformation;
      ToolTip = 'Specifies the isolated test company permitted for generation. It must match the current session company.';
    }
    field(5; "Posting Enabled"; Boolean)
    {
      Caption = 'Posting Enabled';
      ToolTip = 'Specifies whether posting may be requested. Each posting invocation also requires explicit approval.';
    }
    field(10; "Default Process Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Default Process Mode';
      ToolTip = 'Specifies the suggested process scope for a new scenario. This setting never starts generation.';
    }
    field(11; "Default Usage Mode"; Enum "BCSF Usage Mode")
    {
      Caption = 'Default Usage Mode';
      ToolTip = 'Specifies the suggested usage mode for a new scenario.';
    }
    field(12; "Default Seed"; Integer)
    {
      Caption = 'Default Seed';
      InitValue = 1;
      ToolTip = 'Specifies the suggested integer seed. Seed-based generation is implemented separately.';
    }
    field(13; "Default Batch Size"; Integer)
    {
      Caption = 'Default Batch Size';
      InitValue = 100;
      ToolTip = 'Specifies the suggested batch size. It must be positive and cannot exceed the maximum batch size.';
    }
    field(14; "Maximum Batch Size"; Integer)
    {
      Caption = 'Maximum Batch Size';
      InitValue = 1000;
      ToolTip = 'Specifies the largest permitted batch size. It cannot exceed the maximum records per entity.';
    }
    field(15; "Maximum Records per Entity"; Integer)
    {
      Caption = 'Maximum Records per Entity';
      InitValue = 100000;
      ToolTip = 'Specifies the record limit checked for each entity request. It is a configurable limit, not a throughput guarantee.';
    }
    field(18; "Default Data Language"; Enum "BCSF Data Language")
    {
      Caption = 'Default Generated Data Language';
      ToolTip = 'Specifies the default data language for new scenarios. Automatic uses German for any German BC language and English otherwise.';
    }
  }

  keys
  {
    key(PK; "Primary Key")
    {
      Clustered = true;
    }
  }

  trigger OnInsert()
  begin
    ValidateSettings();
  end;

  trigger OnModify()
  begin
    ValidateSettings();
  end;

  /// <summary>Validates the complete setup, including assignments that did not run field validation.</summary>
  procedure ValidateSettings()
  begin
    TestField("Primary Key", GetSetupKey());
    TestField("Allowed Environment Name");
    TestField("Allowed Company Name");
    if not ("Default Data Language" in ["BCSF Data Language"::Automatic, "BCSF Data Language"::German, "BCSF Data Language"::English]) then
      FieldError("Default Data Language", UnknownModeErr);
    if "Default Batch Size" <= 0 then
      FieldError("Default Batch Size", PositiveValueErr);
    if "Maximum Batch Size" <= 0 then
      FieldError("Maximum Batch Size", PositiveValueErr);
    if "Maximum Records per Entity" <= 0 then
      FieldError("Maximum Records per Entity", PositiveValueErr);
    if "Default Batch Size" > "Maximum Batch Size" then
      FieldError("Default Batch Size", BatchLimitErr);
    if "Maximum Batch Size" > "Maximum Records per Entity" then
      FieldError("Maximum Batch Size", EntityLimitErr);
    case "Default Process Mode" of
      "BCSF Process Mode"::SetupAndMasterData,
      "BCSF Process Mode"::UnpostedDocuments:
        ;
      "BCSF Process Mode"::PostedMovements,
      "BCSF Process Mode"::FollowUpProcesses:
        if not "Posting Enabled" then
          FieldError("Posting Enabled", PostingRequiredErr);
      else
        FieldError("Default Process Mode", UnknownModeErr);
    end;
    case "Default Usage Mode" of
      "BCSF Usage Mode"::Demo,
      "BCSF Usage Mode"::Training,
      "BCSF Usage Mode"::Functional,
      "BCSF Usage Mode"::Performance:
        ;
      else
        FieldError("Default Usage Mode", UnknownModeErr);
    end;
  end;

  procedure GetSetupKey(): Code[10]
  begin
    exit('SETUP');
  end;

  var
    PositiveValueErr: Label 'Enter a value greater than zero.';
    BatchLimitErr: Label 'Enter a value that does not exceed Maximum Batch Size.';
    EntityLimitErr: Label 'Enter a value that does not exceed Maximum Records per Entity.';
    PostingRequiredErr: Label 'Enable posting before selecting a default mode that posts documents.';
    UnknownModeErr: Label 'Select a supported mode.';
}
