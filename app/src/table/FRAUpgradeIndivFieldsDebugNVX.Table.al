table 60001 "FRAUpgradeIndivFieldsDebugNVX"
{
    Caption = 'Upgrade IndivFields Debug';
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Statement Text"; Text[250])
        {
            Caption = 'Statement Text';
            DataClassification = SystemMetadata;
        }
        field(3; "Statement Text Finished"; Boolean)
        {
            Caption = 'Statement Text Finished';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}