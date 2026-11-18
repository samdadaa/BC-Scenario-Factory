namespace BCScenarioFactory.ScenarioManagement;

using BCScenarioFactory.Core;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 90125 "BCSF Scenario"
{
  Access = Internal;
  Caption = 'Scenario';
  DataClassification = CustomerContent;
  DataPerCompany = true;

  fields
  {
    field(1; "Scenario Id"; Guid)
    {
      Caption = 'Scenario ID';
      ToolTip = 'Specifies the stable identity of this template.';
      Editable = false;
    }
    field(2; "Description"; Text[100])
    {
      Caption = 'Description';
      ToolTip = 'Specifies the purpose of this scenario template.';
    }
    field(3; "Revision"; Integer)
    {
      Caption = 'Revision';
      ToolTip = 'Specifies the revision, including module and target changes.';
      Editable = false;
    }
    field(4; "Profile Code"; Code[20])
    {
      Caption = 'Profile Code';
      ToolTip = 'Specifies the intended industry profile identifier.';
    }
    field(5; "Profile Version"; Code[20])
    {
      Caption = 'Profile Version';
      ToolTip = 'Specifies the profile version captured with each run.';
    }
    field(6; "Usage Mode"; Enum "BCSF Usage Mode")
    {
      Caption = 'Usage Mode';
      ToolTip = 'Specifies whether the scenario is intended for demos, training or tests.';
    }
    field(7; "Process Mode"; Enum "BCSF Process Mode")
    {
      Caption = 'Maximum Process Scope';
      ToolTip = 'Specifies the highest process mode allowed for entity targets.';
    }
    field(8; "Seed"; Integer)
    {
      Caption = 'Seed';
      ToolTip = 'Specifies the seed captured for reproducible input data.';
    }
    field(9; "Starting Date"; Date)
    {
      Caption = 'Starting Date';
      ToolTip = 'Specifies the first date in the scenario period.';
    }
    field(10; "Ending Date"; Date)
    {
      Caption = 'Ending Date';
      ToolTip = 'Specifies the last date in the scenario period.';
    }
    field(11; "Data Language"; Enum "BCSF Data Language")
    {
      Caption = 'Generated Data Language';
      ToolTip = 'Specifies the data language. Automatic resolves German variants to German and all other languages to English when a run is captured.';
    }
    field(12; "Batch Size"; Integer)
    {
      Caption = 'Batch Size';
      ToolTip = 'Specifies the requested batch size, capped by the factory limits.';
    }
    field(13; "Finance Mode"; Enum "BCSF Finance Mode")
    {
      Caption = 'Finance Setup';
      ToolTip = 'Specifies which finance setup the scenario expects. A test package must already be applied in this company.';
    }
    field(14; "Partner Country Code"; Code[10])
    {
      Caption = 'Partner Country/Region';
      ToolTip = 'Specifies the existing country code for synthetic partner addresses.';
      TableRelation = "Country/Region";
    }
    field(15; "Customer Posting Group"; Code[20])
    {
      Caption = 'Customer Posting Group';
      ToolTip = 'Specifies the exact existing customer posting group. Test packages supply their own group.';
      TableRelation = "Customer Posting Group";
    }
    field(16; "Vendor Posting Group"; Code[20])
    {
      Caption = 'Vendor Posting Group';
      ToolTip = 'Specifies the exact existing vendor posting group. Test packages supply their own group.';
      TableRelation = "Vendor Posting Group";
    }
    field(17; "Gen. Bus. Posting Group"; Code[20])
    {
      Caption = 'General Business Posting Group';
      ToolTip = 'Specifies the exact existing general business posting group. Test packages supply their own group.';
      TableRelation = "Gen. Business Posting Group";
    }
    field(18; "VAT Bus. Posting Group"; Code[20])
    {
      Caption = 'VAT Business Posting Group';
      ToolTip = 'Specifies the exact existing VAT business posting group. Test packages supply their own group.';
      TableRelation = "VAT Business Posting Group";
    }
    field(19; "Cash Terms Code"; Code[10])
    {
      Caption = 'B2C Payment Terms';
      ToolTip = 'Specifies existing terms due immediately without a payment discount for synthetic consumer customers.';
      TableRelation = "Payment Terms";
    }
    field(20; "Small Terms Code"; Code[10])
    {
      Caption = 'Small Partner Payment Terms';
      ToolTip = 'Specifies existing payment terms for the small synthetic partner class.';
      TableRelation = "Payment Terms";
    }
    field(21; "Medium Terms Code"; Code[10])
    {
      Caption = 'Medium Partner Payment Terms';
      ToolTip = 'Specifies existing payment terms for the medium synthetic partner class.';
      TableRelation = "Payment Terms";
    }
    field(22; "Large Terms Code"; Code[10])
    {
      Caption = 'Large Partner Payment Terms';
      ToolTip = 'Specifies existing payment terms for the large synthetic partner class.';
      TableRelation = "Payment Terms";
    }
    field(23; "B2C Percent"; Integer)
    {
      Caption = 'Consumer Customer Percentage';
      ToolTip = 'Specifies the synthetic consumer share as a sampling probability, not an exact quota.';
      InitValue = 15;
      MinValue = 0;
      MaxValue = 100;
    }
    field(24; "Small Credit Limit"; Decimal)
    {
      Caption = 'Small Customer Credit Limit';
      ToolTip = 'Specifies the credit limit in local currency for small business customers. Zero means no credit limit.';
      InitValue = 1000;
      MinValue = 0;
      DecimalPlaces = 0 : 2;
    }
    field(25; "Medium Credit Limit"; Decimal)
    {
      Caption = 'Medium Customer Credit Limit';
      ToolTip = 'Specifies the credit limit in local currency for medium business customers. Zero means no credit limit.';
      InitValue = 10000;
      MinValue = 0;
      DecimalPlaces = 0 : 2;
    }
    field(26; "Large Credit Limit"; Decimal)
    {
      Caption = 'Large Customer Credit Limit';
      ToolTip = 'Specifies the credit limit in local currency for large business customers. Zero means no credit limit.';
      InitValue = 100000;
      MinValue = 0;
      DecimalPlaces = 0 : 2;
    }
    field(27; "B2C Credit Limit"; Decimal)
    {
      Caption = 'Consumer Customer Credit Limit';
      ToolTip = 'Specifies the consumer credit limit in local currency. Zero means no credit limit and does not enforce advance payment.';
      InitValue = 0;
      MinValue = 0;
      DecimalPlaces = 0 : 2;
    }
  }

  keys
  {
    key(PK; "Scenario Id") { Clustered = true; }
  }
}
