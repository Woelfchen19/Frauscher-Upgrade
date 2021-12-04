report 60000 "FRAFillUpgradeTablesStep1NVX"
{
    ApplicationArea = All;
    Caption = 'Fill Upgrade Table (Step 1)';
    ProcessingOnly = true;
    UsageCategory = Administration;

    dataset
    {
        dataitem(DataLoop; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                AllObject: Record AllObj;
                UpdateNeeded: Boolean;
            begin
                if SQLExportType = SQLExportType::"AL" then
                    Window.Open(WindowDlgTxt)
                else
                    Window.Open(SQLWindowDlgTxt);
                // debug - begin
                UPGDebugTable.DeleteAll();
                DebugCounter := 1;
                // debug - end

                // Backup company-wise tables
                SQLServerConnect();
                if (SQLExportType = SQLExportType::SQL) then begin
                    if SQLSaveInSQLTable then
                        SQLCreateSQLUpgradeTable();
                    SQLSendSQLStatement(StrSubstNo('TRUNCATE TABLE [%1]', SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name')));
                end;
                if SQLExportType = SQLExportType::"AL" then
                    if not UPGUpgradeTable.IsEmpty() then
                        UPGUpgradeTable.DeleteAll();

                Commit();
                if Company.FindSet() then
                    repeat
                        Window.Update(1, Company.Name);
                        Window.Update(2, PadStr('', 10, ' '));
                        Sleep(100);
                        AllObject.Reset();
                        AllObject.SetRange("Object Type", AllObject."Object Type"::TableData);
                        AllObject.SetFilter("Object ID", '1..49999|5005270..5005363|99000750..99008535');
                        if AllObject.FindSet() then
                            repeat
                                // update needed?
                                UpdateNeeded := false;
                                if IsModulTable(AllObject."Object ID") then
                                    UpdateNeeded := true;
                                if not UpdateNeeded then
                                    UpdateNeeded := IsStandardModulTable(AllObject."Object ID");
                                if UpdateNeeded then
                                    // check if DataPerCompany
                                    if SQLGetTableHasData(AllObject."Object ID", Company.Name) = 1 then
                                        case SQLExportType of
                                            SQLExportType::SQL:
                                                SQLBackupTable(AllObject."Object ID", Company.Name, IsModulTable(AllObject."Object ID"));
                                            else
                                                if IsModulTable(AllObject."Object ID") then
                                                    BackupModulTable(AllObject."Object ID", Company.Name)
                                                else
                                                    if IsStandardModulTable(AllObject."Object ID") then
                                                        BackupStandardTable(AllObject."Object ID", Company.Name);
                                        end;

                            until AllObject.Next() = 0;
                    until Company.Next() = 0;

                // Backup not company-wise tables
                AllObject.Reset();
                AllObject.SetRange("Object Type", AllObject."Object Type"::TableData);
                AllObject.SetFilter("Object ID", '1..49999|5005270..5005363|99000750..99008535');
                if AllObject.FindSet() then begin
                    Window.Update(1, 'Global Data');
                    Window.Update(2, PadStr('', 10, ' '));
                    Sleep(100);
                    repeat
                        // update needed?
                        UpdateNeeded := false;
                        if IsModulTable(AllObject."Object ID") then
                            UpdateNeeded := true;
                        if not UpdateNeeded then
                            UpdateNeeded := IsStandardModulTable(AllObject."Object ID");
                        if UpdateNeeded then
                            if SQLGetTableHasData(AllObject."Object ID", '') = 2 then
                                case SQLExportType of
                                    SQLExportType::SQL:
                                        SQLBackupTable(AllObject."Object ID", '', IsModulTable(AllObject."Object ID"));
                                    else
                                        if IsModulTable(AllObject."Object ID") then
                                            BackupModulTable(AllObject."Object ID", '')
                                        else
                                            if IsStandardModulTable(AllObject."Object ID") then
                                                BackupStandardTable(AllObject."Object ID", '');
                                end;
                    until AllObject.Next() = 0;
                end;

                if (SQLExportType = SQLExportType::SQL) then begin
                    Commit();
                    if SQLSaveInSQLTable then
                        SQLTransferToSQLUpgradeTable();
                end;

                SQLServerDisconnect();
            end;

            trigger OnPostDataItem()
            begin
                GlobalLanguage(CurrentLanguage);
                Window.Close();
                Message(DoneMsg + StrSubstNo('\\%1 - %2 = %3', SQLTempStartTime, CurrentDateTime(), CurrentDateTime - SQLTempStartTime));
            end;

            trigger OnPreDataItem()
            begin
                if not Confirm(StrSubstNo(FillUpgradeTableQst, UPGUpgradeTable.TableCaption), false) then
                    Error(UserErr);

                SQLTempStartTime := CurrentDateTime();

                CurrentLanguage := GlobalLanguage;
                GlobalLanguage(1033);
            end;
        }
    }

    requestpage
    {
        Caption = 'Fill Upgrade Table (Step 1)';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(SQLExportTypeField; SQLExportType)
                    {
                        ApplicationArea = All;
                        OptionCaption = 'AL,SQL';
                        Caption = 'Type of export';
                        ToolTip = 'Specify whether you want to export the data by SQL script (recommended) or by AL.';

                        trigger OnValidate()
                        begin
                            SQLSaveinSQLTableEnabled := SQLExportType = SQLExportType::SQL;
                        end;
                    }

                    field(SQLSaveInSQLTableField; SQLSaveInSQLTable)
                    {
                        ApplicationArea = All;
                        Enabled = SQLSaveinSQLTableEnabled;
                        Caption = 'Save in separate SQL table';
                        ToolTip = 'If the option is set, the saved data will be transferred from the Upgrade Table to a new SQL table that is independent from NAV/BC. If the option is not selected, SQL will only save to the Upgrade Table and not to the separate SQL table.';
                    }

                    field(SQLServerNameField; SQLServerName)
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        Caption = 'SQL Server+Instance';
                        ToolTip = 'Specify the SQL Server and the instance.';
                    }


                    field(SQLDatabaseNameField; SQLDatabaseName)
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        Caption = 'SQL Database';
                        ToolTip = 'Specify the SQL Database.';
                    }
                    field(SQLNTAuthentificationField; SQLNTAuthentification)
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        Caption = 'NT Authentification';
                        ToolTip = 'Specify whether you want to use Windows authentication.';

                        trigger OnValidate()
                        begin
                            if SQLNTAuthentification then begin
                                SQLNTAuthentificationActivated := true;
                                SQLUserID := '';
                                SQLPassword := '';
                            end else
                                SQLNTAuthentificationActivated := false;
                        end;
                    }
                    field(SQLUserIDField; SQLUserID)
                    {
                        ApplicationArea = All;
                        Caption = 'User Name';
                        ShowMandatory = true;
                        Editable = NOT SQLNTAuthentificationActivated;
                        ToolTip = 'Specifies the username.';
                    }
                    field(SQLPasswordField; SQLPassword)
                    {
                        ApplicationArea = All;
                        Caption = 'Password';
                        ShowMandatory = true;
                        Editable = NOT SQLNTAuthentificationActivated;
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password.';
                    }
                    field(DebugField; DoDebug)
                    {
                        ApplicationArea = All;
                        Enabled = SQLSaveinSQLTableEnabled;
                        Caption = 'Debug Statements';
                        ToolTip = 'If this optin is set, the statements will be stored in T71501.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            SQLExportType := SQLExportType::SQL;
            if SQLNTAuthentification then begin
                SQLNTAuthentificationActivated := true;
                SQLUserID := '';
                SQLPassword := '';
            end else
                SQLNTAuthentificationActivated := false;
            SQLSaveinSQLTableEnabled := SQLExportType = SQLExportType::SQL;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SQLServerName := SQLGetServerInstanceName();
        SQLDatabaseName := CopyStr(SQLGetDatabaseName(), 1, MaxStrLen(SQLDatabaseName));
    end;

    trigger OnPostReport()
    begin
        SelectLatestVersion();
    end;

    trigger OnPreReport()
    begin
        SelectLatestVersion();
    end;

    var
        UPGDebugTable: Record FRAUpgradeIndivFieldsDebugNVX;
        Company: Record Company;
        UPGUpgradeTable: Record FRAUpgradeIndivFieldsNVX;
        TempUPGUpgradeTable: Record FRAUpgradeIndivFieldsNVX temporary;
        Window: Dialog;
        ExportTotal: Integer;
        EntryNo: Integer;
        CurrentLanguage: Integer;
        SQLNTAuthentification: Boolean;
        SQLUserID: Text[100];
        SQLPassword: Text[100];
        SQLServerName: Text[100];
        SQLDatabaseName: Text[100];
        SQLInvalidIdentifierChars: Code[10];
        SQLConnection: DotNet "UPG SqlConnectionNVX";
        SQLTempStartTime: DateTime;
        SQLWindowDlgTxt: Label 'Backup of Company #1#####################################\Table #2#####################################', comment = 'DEA="%1 Firma %2 Tabelle"';
        DoneMsg: Label 'The Backup is done successfully.';
        FillUpgradeTableQst: Label 'Do you want to fill the Upgrade Table with all Modul Data? The data in table %1 will be deleted automatically first.', Comment = 'DEA=%1 Tabelle';
        UserErr: Label 'Cancel by user';
        SQLExportType: Option "AL",SQL;
        [InDataSet]
        SQLNTAuthentificationActivated: Boolean;
        [InDataSet]
        SQLSaveinSQLTableEnabled: Boolean;
        SQLSaveInSQLTable: Boolean;
        SQLUpgradeTableLbl: Label 'FRAUUpgradeIndivFieldsNVX';
        DebugCounter: Integer;
        DoDebug: Boolean;
        WindowDlgTxt: Label 'Backup of Company #1#####################################\Table #2##################################### Remaining #3########', comment = 'DEA=%1 Firma %2 Tabelle %3 verbleibend';

    local procedure IsModulTable(TableID: Integer): Boolean
    begin
        // Is Modul Table?
        if not ModulFieldFilterNeeded(TableID) then
            exit(true);
        exit(false);
    end;

    local procedure IsStandardModulTable(TableID: Integer): Boolean
    var
        FieldsRec: Record "Field";
    begin
        // Is there any Modul Field in the Table?
        FieldsRec.Reset();
        FieldsRec.SetRange(TableNo, TableID);
        FieldsRec.SetFilter("No.", GetModulFilter());
        FieldsRec.SetRange(Enabled, true);
        FieldsRec.SetRange(Class, FieldsRec.Class::Normal);
        FieldsRec.SetRange(ObsoleteState, FieldsRec.ObsoleteState::No);
        if not FieldsRec.IsEmpty() then
            exit(true);

        exit(false);
    end;

    procedure BackupModulTable(TableID: Integer; UseCompanyName: Text[80])
    var
        ExportFields: Record "Field";
        RecRef: RecordRef;
        Dummy: Text[1024];
        i: Integer;
        j: Integer;
    begin
        Clear(RecRef);

        if UseCompanyName <> '' then
            RecRef.Open(TableID, false, UseCompanyName)
        else
            RecRef.Open(TableID);
        ExportFields.Filtergroup(99);
        ExportFields.SetFilter("No.", '<2000000000');
        ExportFields.Filtergroup(0);

        ExportFields.SetRange(TableNo, TableID);
        ExportFields.SetRange(Enabled, true);
        ExportFields.SetRange(Class, ExportFields.Class::Normal);
        ExportFields.SetRange(ObsoleteState, ExportFields.ObsoleteState::No);
        Window.Update(2, RecRef.Caption);
        Sleep(100);
        if RecRef.FindSet() then begin
            EntryNo := 1;
            i := RecRef.Count;
            if i > 10000 then
                j := 100
            else
                if i > 1000 then
                    j := 10
                else
                    j := 1;
            if SQLExportType = SQLExportType::"AL" then
                Window.Update(3, i);
            repeat
                if i mod j = 0 then
                    if SQLExportType = SQLExportType::"AL" then
                        Window.Update(3, i);
                i -= 1;
                if ExportFields.FindSet() then
                    repeat
                        UPGUpgradeTable.Init();
                        UPGUpgradeTable."Company Name" := UseCompanyName;
                        UPGUpgradeTable."Table Number" := TableID;
                        UPGUpgradeTable."Entry Number" := EntryNo;
                        UPGUpgradeTable."Field Number" := ExportFields."No.";
                        UPGUpgradeTable."Record Key" := CopyStr(RecRef.GetPosition(false), 1, MaxStrLen(UPGUpgradeTable."Record Key"));
                        GetDummyValue(ExportFields, Dummy, RecRef);
                        if StrLen(Dummy) > 0 then
                            UPGUpgradeTable.Insert();
                    until ExportFields.Next() = 0;
                EntryNo := EntryNo + 1;
                ExportTotal := ExportTotal + 1;
            until RecRef.Next() = 0;
        end;
        RecRef.Close();
        Commit();
    end;

    local procedure BackupStandardTable(TableID: Integer; UseCompanyName: Text)
    var
        ExportFields: Record "Field";
        T287: Record "Customer Bank Account";
        T288: Record "Vendor Bank Account";
        KeyRecRef: RecordRef;
        RecRef: RecordRef;
        FieldsRef: FieldRef;
        i: Integer;
        j: Integer;
        Dummy: Text[1024];
        KeyFieldsFilter: Text;
        PrimaryKeyRef: KeyRef;
        ModulValueFound: Boolean;
        BlockedAccount: Boolean;
        FieldFilter: Text[1024];
    begin
        if (SQLExportType = SQLExportType::SQL) or (TableID in [287, 288]) then begin
            KeyFieldsFilter := '';
            KeyRecRef.Open(TableID, true);
            PrimaryKeyRef := KeyRecRef.KeyIndex(1);
            for i := 1 to PrimaryKeyRef.FieldCount do
                if KeyFieldsFilter = '' then
                    KeyFieldsFilter := Format(PrimaryKeyRef.FieldIndex(i).Number)
                else
                    KeyFieldsFilter := KeyFieldsFilter + '|' + Format(PrimaryKeyRef.FieldIndex(i).Number);
            KeyRecRef.Close();
            FieldFilter := KeyFieldsFilter + '|' + GetModulFilter();
        end else
            FieldFilter := CopyStr(GetModulFilter(), 1, MaxStrLen(FieldFilter));

        Clear(RecRef);

        if UseCompanyName <> '' then
            RecRef.Open(TableID, false, UseCompanyName)
        else
            RecRef.Open(TableID);

        // save "blocked" Customer and Vendor bank accounts
        if TableID in [287, 288] then
            if UseCompanyName <> '' then begin
                T287.ChangeCompany(UseCompanyName);
                T288.ChangeCompany(UseCompanyName);
            end;

        ExportFields.Reset();
        ExportFields.SetRange(TableNo, TableID);
        ExportFields.SetFilter("No.", FieldFilter);

        ExportFields.Filtergroup(99);
        ExportFields.SetFilter("No.", '<2000000000');
        ExportFields.Filtergroup(0);

        ExportFields.SetRange(Enabled, true);
        ExportFields.SetRange(Class, ExportFields.Class::Normal);
        ExportFields.SetRange(ObsoleteState, ExportFields.ObsoleteState::No);
        Window.Update(2, RecRef.Caption);
        Sleep(100);

        if RecRef.FindSet() then begin
            EntryNo := 0;
            i := RecRef.Count;
            if i > 10000 then
                j := 100
            else
                if i > 1000 then
                    j := 10
                else
                    j := 1;
            if SQLExportType = SQLExportType::"AL" then
                Window.Update(3, i);
            repeat
                // EntryNo := 0;
                EntryNo := EntryNo + 1;
                TempUPGUpgradeTable.DeleteAll();
                ModulValueFound := false;
                BlockedAccount := false;
                // detect "blocked" or imported Customer and Vendor bank accounts
                if TableID = 287 then begin
                    RecRef.SetTable(T287);
                    ExportFields.SetRange("No.", 5157802);
                    if ExportFields.FindFirst() then begin
                        FieldsRef := RecRef.Field(ExportFields."No.");
                        if FieldsRef.Value then begin
                            BlockedAccount := true;
                            ModulValueFound := true;
                        end;
                    end;
                    ExportFields.SetRange("No.");

                    if (T287."Customer No." = '') then begin
                        BlockedAccount := true;
                        ModulValueFound := true;
                    end;
                    if not BlockedAccount then
                        ExportFields.SetFilter("No.", FieldFilter);
                end;
                if TableID = 288 then begin
                    RecRef.SetTable(T288);
                    ExportFields.SetRange("No.", 5157802);
                    if ExportFields.FindFirst() then begin
                        FieldsRef := RecRef.Field(ExportFields."No.");
                        if FieldsRef.Value then begin
                            BlockedAccount := true;
                            ModulValueFound := true;
                        end;
                    end;
                    ExportFields.SetRange("No.");
                    if (T288."Vendor No." = '') then begin
                        BlockedAccount := true;
                        ModulValueFound := true;
                    end;
                    if not BlockedAccount then
                        ExportFields.SetFilter("No.", FieldFilter);
                end;
                if i mod j = 0 then
                    if SQLExportType = SQLExportType::"AL" then
                        Window.Update(3, i);
                i -= 1;
                if ExportFields.FindSet() then begin
                    repeat
                        UPGUpgradeTable.Init();
                        UPGUpgradeTable."Company Name" := CopyStr(UseCompanyName, 1, MaxStrLen(UPGUpgradeTable."Company Name"));
                        UPGUpgradeTable."Table Number" := TableID;
                        UPGUpgradeTable."Entry Number" := EntryNo;
                        UPGUpgradeTable."Field Number" := ExportFields."No.";
                        UPGUpgradeTable."Record Key" := CopyStr(RecRef.GetPosition(false), 1, MaxStrLen(UPGUpgradeTable."Record Key"));
                        GetDummyValue(ExportFields, Dummy, RecRef);
                        if StrLen(Dummy) > 0 then begin
                            // mark imported C/V bank accounts
                            if (UPGUpgradeTable."Table Number" in [287, 288]) and
                               (UPGUpgradeTable."Field Number" = 5157802) and
                               UPGUpgradeTable."Value as Boolean"
                            then
                                BlockedAccount := true;
                            if ExportFields."No." >= 50000 then begin
                                ModulValueFound := true;
                                UPGUpgradeTable.Insert();
                            end else begin
                                TempUPGUpgradeTable.Init();
                                TempUPGUpgradeTable."Company Name" := CopyStr(UseCompanyName, 1, MaxStrLen(TempUPGUpgradeTable."Company Name"));
                                TempUPGUpgradeTable."Table Number" := TableID;
                                TempUPGUpgradeTable."Entry Number" := EntryNo;
                                TempUPGUpgradeTable."Field Number" := ExportFields."No.";
                                TempUPGUpgradeTable."Value as Text" := Dummy;
                                TempUPGUpgradeTable."Record Key" := CopyStr(RecRef.GetPosition(false), 1, MaxStrLen(TempUPGUpgradeTable."Record Key"));
                                TempUPGUpgradeTable.Insert();
                            end;
                        end;
                    until ExportFields.Next() = 0;
                    if ModulValueFound then
                        if TempUPGUpgradeTable.FindSet() then begin
                            repeat
                                UPGUpgradeTable := TempUPGUpgradeTable;
                                if not UPGUpgradeTable.Insert() then
                                    UPGUpgradeTable.Modify();
                            until TempUPGUpgradeTable.Next() = 0;
                            TempUPGUpgradeTable.DeleteAll();
                        end;
                end;
                if ModulValueFound then
                    ExportTotal := ExportTotal + 1;
            until RecRef.Next() = 0;
        end;
        RecRef.Close();
        Commit();
    end;

    local procedure GetModulFilter(): Text
    begin
        exit('50000..99999');
    end;

    local procedure ModulFieldFilterNeeded(TableID: Integer): Boolean
    begin
        if TableID in [50000, 99999] then
            exit(false)
        else
            exit(true);
    end;


    local procedure GetDummyValue(var ExportFields: Record "Field"; var Dummy: Text[1024]; var RecRef: RecordRef)
    var
        FieldsRef: FieldRef;
        DummyDateForm: DateFormula;
        EmptyDateForm: DateFormula;
        DummyDec: Decimal;
        DummyBoolean: Boolean;
        DummyBigInt: BigInteger;
        DummyDateTime: DateTime;
        DummyDate: Date;
        DummyTime: Time;
        DummyGUID: Guid;
        EmptyGUID: Guid;
    begin
        Dummy := '';
        FieldsRef := RecRef.Field(ExportFields."No.");
        case ExportFields.Type of
            ExportFields.Type::Integer, ExportFields.Type::Option, ExportFields.Type::BigInteger:
                begin
                    DummyBigInt := FieldsRef.Value;
                    Dummy := Format(DummyBigInt);
                    UPGUpgradeTable."Value as BigInteger" := DummyBigInt;
                    if DummyBigInt = 0 then
                        Dummy := '';
                end;
            ExportFields.Type::Text, ExportFields.Type::Code:
                begin
                    Dummy := Format(FieldsRef.Value);
                    UPGUpgradeTable."Value as Text" := Dummy;
                end;
            ExportFields.Type::GUID:
                begin
                    DummyGUID := FieldsRef.Value;
                    UPGUpgradeTable."Value as Text" := Format(DummyGUID);
                    Dummy := UPGUpgradeTable."Value as Text";
                    if DummyGUID = EmptyGUID then
                        Dummy := '';
                end;
            ExportFields.Type::DateFormula:
                begin
                    if (Format(FieldsRef.Value) = '0') or (Format(FieldsRef.Value) = '') then
                        Evaluate(DummyDateForm, '0D')
                    else
                        DummyDateForm := FieldsRef.Value;
                    UPGUpgradeTable."Value as Text" := Format(DummyDateForm);
                    Dummy := UPGUpgradeTable."Value as Text";
                    if DummyDateForm = EmptyDateForm then
                        Dummy := '';
                end;

            ExportFields.Type::Decimal:
                begin
                    DummyDec := FieldsRef.Value;
                    Dummy := Format(DummyDec);
                    UPGUpgradeTable."Value as Decimal" := DummyDec;
                    if DummyDec = 0 then
                        Dummy := '';
                end;
            ExportFields.Type::Date:
                begin
                    DummyDate := FieldsRef.Value;
                    Dummy := Format(DummyDate);
                    UPGUpgradeTable."Value as Date" := DummyDate;
                    if DummyDate = 0D then
                        Dummy := '';
                end;
            ExportFields.Type::Time:
                begin
                    DummyTime := FieldsRef.Value;
                    Dummy := Format(DummyTime);
                    UPGUpgradeTable."Value as Time" := DummyTime;
                    if DummyTime = 0T then
                        Dummy := '';
                end;
            ExportFields.Type::DateTime:
                begin
                    DummyDateTime := FieldsRef.Value;
                    Dummy := Format(DummyDateTime);
                    UPGUpgradeTable."Value as DateTime" := DummyDateTime;
                end;
            ExportFields.Type::Boolean:
                begin
                    DummyBoolean := FieldsRef.Value;
                    Dummy := Format(DummyBoolean);
                    UPGUpgradeTable."Value as Boolean" := DummyBoolean;
                    if not DummyBoolean then
                        Dummy := '';
                end;
        end;
    end;

    local procedure SQLBackupTable(TableID: Integer; UseCompanyName: Text; ModulTable: Boolean)
    var
        ExportFields: Record "Field";
        RecRef: RecordRef;
        KeyRecRef: RecordRef;
        KeyFieldsFilter: Text;
        PrimaryKeyRef: KeyRef;
        SQLStmt: Text;
        i: Integer;
        RecordKeyPart: Text;
        OrderByPKPart: Text;
        SubPart: Text;
        SQLTableName: Text;
        EmptyValuePart: Text;
        IsPartOfPK: Integer;
        ValueFieldpart: Text;
        PKPart: Text;
        Type: Integer;
    begin
        KeyFieldsFilter := '';

        Clear(KeyRecRef);
        KeyRecRef.Open(TableID, true);
        PrimaryKeyRef := KeyRecRef.KeyIndex(1);

        for i := 1 to PrimaryKeyRef.FieldCount do begin
            if RecordKeyPart <> '' then begin
                RecordKeyPart += ',';
                PKPart += '+''|''+';
                OrderByPKPart += ',';
            end;
            ExportFields.Get(TableID, PrimaryKeyRef.FieldIndex(i).Number);
            // IF GUID do not change into NVARCHAR
            if ExportFields.Type <> ExportFields.Type::GUID then begin
                RecordKeyPart += StrSubstNo('Field%1=0(''+CONVERT(NVARCHAR(MAX),[%2])+'')', Format(PrimaryKeyRef.FieldIndex(i).Number), SQLReplaceInvalidChars(PrimaryKeyRef.FieldIndex(i).Name));
                PKPart += StrSubstNo('CONVERT(NVARCHAR,[%1])', SQLReplaceInvalidChars(PrimaryKeyRef.FieldIndex(i).Name));
            end else begin
                RecordKeyPart += StrSubstNo('Field%1=0(''+CONVERT(CHAR(36),[%2])+'')', Format(PrimaryKeyRef.FieldIndex(i).Number), SQLReplaceInvalidChars(PrimaryKeyRef.FieldIndex(i).Name));
                PKPart += StrSubstNo('CONVERT(CHAR(36),[%1])', SQLReplaceInvalidChars(PrimaryKeyRef.FieldIndex(i).Name));
            end;
            OrderByPKPart += StrSubstNo('[%1]', SQLReplaceInvalidChars(PrimaryKeyRef.FieldIndex(i).Name));
        end;
        RecordKeyPart := 'N''' + RecordKeyPart + '''';
        KeyFieldsFilter := GetModulFilter();
        KeyRecRef.Close();

        Clear(RecRef);

        if UseCompanyName <> '' then
            RecRef.Open(TableID, false, UseCompanyName)
        else
            RecRef.Open(TableID);

        ExportFields.Reset();
        ExportFields.SetRange(TableNo, TableID);
        if not ModulTable then
            ExportFields.SetFilter("No.", KeyFieldsFilter);

        ExportFields.Filtergroup(99);
        ExportFields.SetFilter("No.", '<2000000000');
        ExportFields.Filtergroup(0);

        ExportFields.SetRange(Enabled, true);
        ExportFields.SetRange(Class, ExportFields.Class::Normal);
        ExportFields.SetRange(ObsoleteState, ExportFields.ObsoleteState::No);
        ExportFields.SetFilter(Type, '<>%1', ExportFields.Type::BLOB);

        Window.Update(2, RecRef.Caption);
        Sleep(50);

        if UseCompanyName <> '' then
            SQLTableName := StrSubstNo('%1$%2', SQLReplaceInvalidChars(UseCompanyName), SQLReplaceInvalidChars(RecRef.Name))
        else
            SQLTableName := StrSubstNo('%1', SQLReplaceInvalidChars(RecRef.Name));

        SQLTableName := SQLGetModulTablename(SQLTableName);

        if ExportFields.FindSet() then begin
            SQLStmt := StrSubstNo(';WITH EntryNo AS (SELECT %2 PK, ROW_NUMBER() OVER (ORDER BY %3) EntryNo, %4 RecordKey FROM [%1]),SUB AS(', SQLGetTableName(SQLTableName, ExportFields.FieldName), PKPart, OrderByPKPart, RecordKeyPart);
            repeat
                //Empty Value
                case ExportFields.Type of
                    ExportFields.Type::Integer, ExportFields.Type::Option, ExportFields.Type::Decimal, ExportFields.Type::Boolean, ExportFields.Type::BigInteger:
                        EmptyValuePart := '0';
                    ExportFields.Type::Text, ExportFields.Type::Code, ExportFields.Type::DateFormula:
                        EmptyValuePart := '''''';
                    ExportFields.Type::Date, ExportFields.Type::Time, ExportFields.Type::DateTime:
                        EmptyValuePart := '''01-01-1753''';
                    ExportFields.Type::GUID:
                        EmptyValuePart := '''00000000-0000-0000-0000-000000000000''';
                    else
                        EmptyValuePart := '''''';
                end;
                //Value Field
                case ExportFields.Type of
                    ExportFields.Type::Text, ExportFields.Type::Code, ExportFields.Type::DateFormula, ExportFields.Type::GUID:
                        ValueFieldpart := 'CONVERT(NVARCHAR(MAX),[%5]) ValueAsText, 0 [Value as BigInteger], ''01.01.1753'' [Value as DateTime], 0 [Value as Boolean],0 [Value as Decimal],''01.01.1753'' [Value as Time],''01.01.1753'' [Value as Date]';
                    ExportFields.Type::Integer, ExportFields.Type::Option, ExportFields.Type::BigInteger:
                        ValueFieldpart := ''''' ValueAsText, [%5] [Value as BigInteger], ''01.01.1753'' [Value as DateTime], 0 [Value as Boolean],0 [Value as Decimal],''01.01.1753'' [Value as Time],''01.01.1753'' [Value as Date]';
                    ExportFields.Type::DateTime:
                        ValueFieldpart := ''''' ValueAsText, 0 [Value as BigInteger], [%5] [Value as DateTime], 0 [Value as Boolean],0 [Value as Decimal],''01.01.1753'' [Value as Time],''01.01.1753'' [Value as Date]';
                    ExportFields.Type::Boolean:
                        ValueFieldpart := ''''' ValueAsText, 0 [Value as BigInteger], ''01.01.1753'' [Value as DateTime], [%5] [Value as Boolean],0 [Value as Decimal],''01.01.1753'' [Value as Time],''01.01.1753'' [Value as Date]';
                    ExportFields.Type::Decimal:
                        ValueFieldpart := ''''' ValueAsText, 0 [Value as BigInteger], ''01.01.1753'' [Value as DateTime], 0 [Value as Boolean],[%5] [Value as Decimal],''01.01.1753'' [Value as Time],''01.01.1753'' [Value as Date]';
                    ExportFields.Type::Time:
                        ValueFieldpart := ''''' ValueAsText, 0 [Value as BigInteger], ''01.01.1753'' [Value as DateTime], 0 [Value as Boolean],0 [Value as Decimal],[%5] [Value as Time],''01.01.1753'' [Value as Date]';
                    ExportFields.Type::Date:
                        ValueFieldpart := ''''' ValueAsText, 0 [Value as BigInteger], ''01.01.1753'' [Value as DateTime], 0 [Value as Boolean],0 [Value as Decimal],''01.01.1753'' [Value as Time],[%5] [Value as Date]';
                    else
                        ValueFieldpart := 'CONVERT(NVARCHAR(MAX),[%5]) ValueAsText, 0 [Value as BigInteger], ''01.01.1753'' [Value as DateTime], 0 [Value as Boolean],0 [Value as Decimal],''01.01.1753'' [Value as Time],''01.01.1753'' [Value as Date]';
                end;
                if SubPart <> '' then
                    SubPart += ' UNION ALL ';
                if StrPos(PKPart, '[' + SQLReplaceInvalidChars(ExportFields.FieldName) + ']') > 0 then
                    IsPartOfPK := 1
                else
                    IsPartOfPK := 0;

                Type := 0;
                SubPart += StrSubstNo('SELECT %2 PK, %3 FieldNumber, %4 FieldType, %7 PKPart, ' + ValueFieldpart + ' FROM [%1] WITH (READUNCOMMITTED) WHERE [%5]<>%6', SQLGetTableName(SQLTableName, ExportFields.FieldName), PKPart, ExportFields."No.", Type,
                SQLReplaceInvalidChars(ExportFields.FieldName), EmptyValuePart, IsPartOfPK);
            until ExportFields.Next() = 0;
        end;

        SQLStmt += SubPart + ')';

        SQLStmt += StrSubstNo(
          'INSERT INTO [%1]([Company Name],[Table Number],[Entry Number],' +
            '[Field Number],[Field Type],[Record Key],' +
            '[Value as Text],[Value as BigInteger],[Value as DateTime],[Value as Boolean],[Value as Decimal],' +
            '[Value as Time],[Value as Date])',
          SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name'));

        SQLStmt += StrSubstNo(
          'SELECT ''%1'' CompanyName, %2 TableNumber, EntryNo.EntryNo EntryNo,' +
          'FieldNumber, FieldType, RecordKey,ValueAsText,' +
          '[Value as BigInteger],[Value as DateTime],[Value as Boolean],[Value as Decimal],[Value as Time],' +
          '[Value as Date] FROM SUB s1 INNER JOIN EntryNo ON EntryNo.PK=s1.PK ',
          UseCompanyName, RecRef.Number);

        if not ModulTable then
            SQLStmt += 'WHERE EXISTS(SELECT * FROM SUB s2 WHERE s2.PK=s1.PK AND s2.PKPart = 0)';
        SQLStmt += 'ORDER BY s1.PK';

        SQLSendSQLStatement(SQLStmt);

        RecRef.Close();
    end;

    procedure SQLServerConnect() Result: Boolean
    var
        ConnectionString: Text[250];
        SQLConnectionOK: Boolean;
        SqlConnectionState: DotNet "UPG ConnectionStateNVX";
        InvalidConnectionErr: Label 'The SQL Connection information specified is incorrect.  Please verify the User ID and Password.';
    begin
        // connect to SQL Server
        ConnectionString := SQLGetConnectionString();
        if IsNull(SQLConnection) then
            SQLConnection := SQLConnection.SqlConnection(ConnectionString);
        if not SqlConnectionState.Equals(SQLConnection.State, SqlConnectionState.Open) then
            SQLConnection.Open();
        SQLConnectionOK := SqlConnectionState.Equals(SQLConnection.State, SqlConnectionState.Open);

        if not SQLConnectionOK then
            Error(InvalidConnectionErr);
    end;

    procedure SQLServerDisconnect()
    var
        SqlConnectionState: DotNet "UPG ConnectionStateNVX";
    begin
        // terminate SQL connection
        if IsNull(SQLConnection) then
            exit;
        if SqlConnectionState.Equals(SQLConnection.State, SqlConnectionState.Open) then
            SQLConnection.Close();
        Clear(SQLConnection);
    end;

    procedure SQLSendSQLStatement(Statement: Text)
    var
        SqlConnectionState: DotNet "UPG ConnectionStateNVX";
        SQLCommand: DotNet "UPG SqlCommandNVX";
        ConnectionClosedErr: Label 'The SQL connection to the database has been closed.';
        CutText: Text;
        j: Integer;
        MaxInt: Integer;
    begin
        // debug - begin
        if DoDebug then begin
            MaxInt := Round(StrLen(Statement) / 250, 1) + 1;
            CutText := Statement;
            for j := 1 to MaxInt do
                if CutText <> '' then begin
                    UPGDebugTable.Init();
                    UPGDebugTable."Entry No." := DebugCounter;
                    UPGDebugTable."Statement Text" := CopyStr(CutText, 1, 250);
                    if StrLen(CutText) > 250 then
                        CutText := CopyStr(CutText, 250)
                    else
                        CutText := '';
                    if CutText = '' then
                        UPGDebugTable."Statement Text Finished" := true;
                    DebugCounter := DebugCounter + 1;
                    UPGDebugTable.Insert();
                    Commit();
                end;
        end;
        // debug - end

        // send SQL statement to SQL Server
        if SqlConnectionState.Equals(SQLConnection.State, SqlConnectionState.Open) then begin
            SQLCommand := SQLConnection.CreateCommand();
            SQLCommand.CommandTimeout := 0;
            SQLCommand.CommandText := Statement;
        end else
            Error(ConnectionClosedErr);
        SQLCommand.ExecuteNonQuery();
    end;

    procedure SQLGetConnectionString() Result: Text[250]
    begin
        // detect SQL Server Connection String
        Result := 'Server=' + SQLServerName + ';Language=German';

        if not SQLNTAuthentification then
            Result += ';Trusted_Connection=no;UID=' + SQLUserID + ';pwd=' + SQLPassword + ';'
        else
            Result += ';Trusted_Connection=Yes;';
        Result += ';database=' + DelChr(SQLDatabaseName, '=', '[]');
    end;

    procedure SQLGetSetting("Key": Text): Text
    var
        Value: Text;
        XmlDocument: DotNet "UPG XmlDocumentNVX";
        XmlNode: DotNet "UPG XmlNodeNVX";
    begin
        // read SQL Setting from Config File
        XmlDocument := XmlDocument.XmlDocument();

        XmlDocument.Load(SQLGetCustomSettingsFile());
        XmlNode := XmlDocument.SelectSingleNode('//appSettings/add[@key=''' + Key + ''']');

        if not IsNull(XmlNode) then
            Value := XmlNode.Attributes.Item(1).Value;

        exit(Value);
    end;

    procedure SQLGetServerInstanceName(): Text[100]
    begin
        // detect SQL Server Instance
        if SQLGetSetting('DatabaseInstance') = '' then
            exit(CopyStr(SQLGetSetting('DatabaseServer'), 1, 100))
        else
            exit(SQLGetSetting('DatabaseServer') + '\' + SQLGetSetting('DatabaseInstance'));
    end;

    procedure SQLGetDatabaseName(): Text[100]
    begin
        // detect SQL Database
        exit(CopyStr(SQLGetSetting('DatabaseName'), 1, 100));
    end;

    local procedure SQLGetCustomSettingsFile() ExitValue: Text
    var
        XmlAttribute: DotNet "UPG XmlAttributeNVX";
        XmlDocument: DotNet "UPG XmlDocumentNVX";
        XmlNode: DotNet "UPG XmlNodeNVX";
    begin
        // detect Custom SettingsFile
        ExitValue := ApplicationPath + 'CustomSettings.config';

        XmlDocument := XmlDocument.XmlDocument();

        XmlDocument.Load(SQLGetInstanceSettingsFile());
        XmlNode := XmlDocument.SelectSingleNode('//appSettings');

        if not IsNull(XmlNode) then begin
            XmlAttribute := XmlNode.Attributes.ItemOf('file');
            if not IsNull(XmlAttribute) then begin
                ExitValue := XmlAttribute.Value;
                if StrPos(ExitValue, '\') = 0 then
                    ExitValue := ApplicationPath + ExitValue;
            end;
        end;
    end;

    local procedure SQLGetInstanceSettingsFile() ExitValue: Text
    var
        ImagePath: Text;
        InstanceName: Text;
        InstanceSettingsFile: Text;
        RegistryKey: Text;
        SplitPos: Integer;
        Registry: DotNet "UPG RegistryNVX";
    begin
        // detect SQL Server Instance via setup of NAV/BC Server
        ExitValue := ApplicationPath + 'Microsoft.Dynamics.Nav.Server.exe.config';

        InstanceName := SQLGetInstanceName();
        RegistryKey := 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\MicrosoftDynamicsNavServer$' + InstanceName;
        ImagePath := Registry.GetValue(RegistryKey, 'ImagePath', '');

        SplitPos := StrPos(LowerCase(ImagePath), '$' + LowerCase(InstanceName));

        if SplitPos > 0 then begin
            InstanceSettingsFile := CopyStr(ImagePath, SplitPos + StrLen(InstanceName) + 2);
            SplitPos := StrPos(InstanceSettingsFile, ' ');
            if SplitPos > 0 then begin
                InstanceSettingsFile := CopyStr(InstanceSettingsFile, SplitPos + 1);
                InstanceSettingsFile := DelChr(InstanceSettingsFile, '<>', '"');
                ExitValue := InstanceSettingsFile;
            end;
        end;
    end;

    local procedure SQLGetInstanceName(): Text
    var
        ActiveSession: Record "Active Session";
    begin
        // detect NAV/BC Server Instance via active session
        ActiveSession.SetRange("Server Instance ID", ServiceInstanceId());
        ActiveSession.FindFirst();
        exit(ActiveSession."Server Instance Name");
    end;

    local procedure SQLGetInvalidIdentifierChars(): Text[10]
    var
        DataReader: DotNet "UPG SqlDataReaderNVX";
        SqlCommand: DotNet "UPG SqlCommandNVX";
        SqlConnection2: DotNet "UPG SqlConnectionNVX";
    begin
        // detect invalid characters by system table
        SqlConnection2 := SQLConnection.SqlConnection(SQLGetConnectionString());
        SqlConnection2.Open();
        SqlCommand := SqlConnection2.CreateCommand();

        SqlCommand.CommandText('SELECT invalididentifierchars FROM [$ndo$dbproperty]');
        DataReader := SqlCommand.ExecuteReader();

        if DataReader.Read() then
            exit(DataReader.GetString(0));
    end;

    procedure SQLReplaceInvalidChars(Name: Text) ExitValue: Text
    var
        i: Integer;
    begin
        // replace invalid characters in tablenames and fieldnames
        if SQLInvalidIdentifierChars = '' then
            SQLInvalidIdentifierChars := SQLGetInvalidIdentifierChars();

        ExitValue := Name;

        for i := 1 to StrLen(ExitValue) do
            if StrPos(SQLInvalidIdentifierChars, Format(ExitValue[i])) > 0 then
                ExitValue[i] := '_';
    end;

    local procedure SQLGetTableHasData(TableId: Integer; TableCompanyName: Text): Integer
    var
        HasData: Boolean;
    begin
        // Returncode: 0-Error Table not readable, 1-DataPerCompany, 2-GlobalData, 3-NoData in Table
        if not SQLGetTableCompanyName(TableId, TableCompanyName, HasData) then
            exit(0)
        else
            case true of
                not HasData:
                    exit(3);
                TableCompanyName <> '':
                    exit(1);
                else
                    exit(2);
            end;
    end;

    local procedure SQLGetTableCompanyName(TableID: Integer; var TableCompanyName: Text; var HasData: Boolean): Boolean
    var
        RecRef: RecordRef;
    begin
        // check DataPerCompany flag and existing data
        // via RecRef, because direct check for extensions not possible
        Clear(RecRef);
        if TableCompanyName <> '' then begin
            RecRef.Open(TableID, false, TableCompanyName);
            if not SQLCheckTableExists(StrSubstNo('%1$%2', TableCompanyName, RecRef.Name)) then
                TableCompanyName := '';
        end else begin
            RecRef.Open(TableID);
            if not SQLCheckTableExists(StrSubstNo('%1', RecRef.Name)) then
                exit(false);
        end;
        HasData := not RecRef.IsEmpty;
        RecRef.Close();
        exit(true);
    end;

    local procedure SQLGetTableName(TblName: Text; FldName: Text) Result: Text
    var
        DataReader: DotNet "UPG SqlDataReaderNVX";
        SqlCommand: DotNet "UPG SqlCommandNVX";
    begin
        // check for extensions the SQL table name via table and field name
        Result := SQLReplaceInvalidChars(TblName);

        // detect in which table a field is located, if an extension is installed
        SqlCommand := SQLConnection.CreateCommand();
        SqlCommand.CommandText(StrSubstNo('select t.name from sys.syscolumns c WITH(READUNCOMMITTED) INNER JOIN sys.tables t WITH(READUNCOMMITTED) ON t.[object_id] = c.id where (t.name = ''%1'' or t.name like ''%1$%'') AND c.name = ''%2''',
        SQLReplaceInvalidChars(TblName), SQLReplaceInvalidChars(FldName)));
        DataReader := SqlCommand.ExecuteReader();
        if DataReader.Read() then
            Result := DataReader.GetString(0);
        DataReader.Dispose();
        SqlCommand.Dispose();
    end;

    local procedure SQLCheckTableExists(TblName: Text) Result: Boolean
    var
        DataReader: DotNet "UPG SqlDataReaderNVX";
        SqlCommand: DotNet "UPG SqlCommandNVX";
    begin
        // detect via tablename, whether the table exists: need to check the DataPerCompany Flag
        // this is the only known way for tables in extensions
        Result := false;

        // detect in which table a field is located, if an extension is installed
        SqlCommand := SQLConnection.CreateCommand();
        SqlCommand.CommandText(StrSubstNo('select t.name from sys.tables t WITH(READUNCOMMITTED) where (t.name = ''%1'' or t.name like ''%1$%'')', SQLReplaceInvalidChars(TblName)));
        DataReader := SqlCommand.ExecuteReader();
        Result := DataReader.HasRows;
        DataReader.Dispose();
        SqlCommand.Dispose();
    end;

    local procedure SQLCreateSQLUpgradeTable()
    var
        Statement: Text;
    begin
        Statement := StrSubstNo('IF EXISTS(SELECT * FROM sys.tables where name = ''%1'') DROP TABLE [%1] ', SQLUpgradeTableLbl);

        SQLSendSQLStatement(Statement);

        Statement += StrSubstNo('CREATE TABLE [dbo].[%1]( ', SQLUpgradeTableLbl);
        Statement += '[Company Name] [nvarchar](80) NOT NULL, ';
        Statement += '[Table Number] [int] NOT NULL, ';
        Statement += '[Entry Number] [int] NOT NULL, ';
        Statement += '[Field Number] [int] NOT NULL, ';
        Statement += '[Field Type] [int] NOT NULL, ';
        Statement += '[Value as Text] [nvarchar](1024) NOT NULL, ';
        Statement += '[Record Key] [nvarchar](1024) NOT NULL, ';
        Statement += '[Value as BigInteger] [bigint] NOT NULL, ';
        Statement += '[Value as DateTime] [datetime] NOT NULL, ';
        Statement += '[Value as Boolean] [tinyint] NOT NULL, ';
        Statement += '[Value as Decimal] [decimal](38, 20) NOT NULL, ';
        Statement += '[Value as Time] [datetime] NOT NULL, ';
        Statement += '[Value as Date] [datetime] NOT NULL, ';
        Statement += StrSubstNo(' CONSTRAINT [%1$0] PRIMARY KEY CLUSTERED  ', SQLUpgradeTableLbl);
        Statement += '( ';
        Statement += '[Company Name] ASC, ';
        Statement += '[Table Number] ASC, ';
        Statement += '[Entry Number] ASC, ';
        Statement += '[Field Number] ASC ';
        Statement += ') ';
        Statement += ') ON [PRIMARY] ';

        SQLSendSQLStatement(Statement);
    end;

    local procedure SQLGetModulTablename(TableName2: Text) Result: Text
    begin
        // detect SQL Name of Modul Table (even if it is extension)
        Result := SQLReplaceInvalidChars(TableName2);
        if SQLGetModulAppExtension() <> '' then
            Result += '$' + SQLGetModulAppExtension();
    end;

    local procedure SQLGetModulAppExtension() Result: Text
    var
        NAVApp: Record "NAV App Installed App";
    begin
        // detect APP ID of Frauscher Base extension
        NAVApp.SetRange(Name, 'Frauscher Base');
        if NAVApp.FindFirst() then
            Result := DelChr(LowerCase(NAVApp."App ID"), '=', '{}');
    end;

    local procedure SQLTransferToSQLUpgradeTable()
    var
        Statement: Text;
    begin
        Statement := StrSubstNo('INSERT INTO [dbo].[%1] ', SQLUpgradeTableLbl);
        Statement += '([Company Name],[Table Number],[Entry Number],[Field Number],[Field Type],[Value as Text],[Record Key],[Value as BigInteger],[Value as DateTime],[Value as Boolean],[Value as Decimal],[Value as Time],[Value as Date]) ';
        Statement += 'SELECT [Company Name],[Table Number],[Entry Number],[Field Number],[Field Type],[Value as Text],[Record Key],[Value as BigInteger],[Value as DateTime],[Value as Boolean],[Value as Decimal],[Value as Time],[Value as Date] ';
        Statement += StrSubstNo('FROM [%1] WITH (READUNCOMMITTED)', SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name'));

        SQLSendSQLStatement(Statement);

        Statement := StrSubstNo('TRUNCATE TABLE [%1]', SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name'));

        SQLSendSQLStatement(Statement);
    end;

}