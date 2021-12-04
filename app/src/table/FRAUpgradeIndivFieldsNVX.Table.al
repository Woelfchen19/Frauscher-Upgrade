table 60000 "FRAUpgradeIndivFieldsNVX"
{
    Caption = 'Upgrade IndivFields';
    DataClassification = ToBeClassified;
    DataPerCompany = false;

    fields
    {
        field(1; "Company Name"; Text[80])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(2; "Table Number"; Integer)
        {
            Caption = 'Table Number';
            DataClassification = SystemMetadata;
        }
        field(3; "Entry Number"; BigInteger)
        {
            Caption = 'Record Entry No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Field Number"; Integer)
        {
            Caption = 'Field Number';
            DataClassification = SystemMetadata;
        }
        field(5; "Field Type"; Option)
        {
            Caption = 'Field Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Text,BigInteger,DateTime,Boolean,Decimal,Date,Time,GUID';
            OptionMembers = Text,BigInteger,DateTime,Boolean,Decimal,Date,Time,GUID;
        }
        field(6; "Value as Text"; Text[1024])
        {
            Caption = 'Value as Text';
            DataClassification = SystemMetadata;
        }
        field(7; "Record Key"; Text[1024])
        {
            Caption = 'Record Key';
            DataClassification = SystemMetadata;
        }
        field(8; "Value as BigInteger"; BigInteger)
        {
            Caption = 'Value as BigInteger';
            DataClassification = SystemMetadata;
        }
        field(9; "Value as DateTime"; DateTime)
        {
            Caption = 'Value as DateTime';
            DataClassification = SystemMetadata;
        }
        field(10; "Value as Boolean"; Boolean)
        {
            Caption = 'Value as Boolean';
            DataClassification = SystemMetadata;
        }
        field(11; "Value as Decimal"; Decimal)
        {
            Caption = 'Value as Decimal';
            DataClassification = SystemMetadata;
        }
        field(12; "Value as Time"; Time)
        {
            Caption = 'Value as Time';
            DataClassification = SystemMetadata;
        }
        field(13; "Value as Date"; Date)
        {
            Caption = 'Value as Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Company Name", "Table Number", "Entry Number", "Field Number")
        {
            Clustered = true;
        }
        key(Key2; "Table Number", "Field Number", "Company Name")
        {
        }
        key(Key3; "Company Name", "Table Number", "Field Number")
        {
        }
    }

    fieldgroups
    {
    }
}