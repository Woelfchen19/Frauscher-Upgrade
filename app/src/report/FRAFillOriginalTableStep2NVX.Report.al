report 60001 "FRAFillOriginalTableStep2NVX"
{
    ApplicationArea = All;
    Caption = 'Fill Original Table (Step 2)';
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
                UPGUpgradeTable: Record FRAUpgradeIndivFieldsNVX;
            begin
                if SQLImportType = SQLImportType::"AL" then
                    Window.Open(WindowDlgTxt)
                else
                    Window.Open(SQLWindowDlgTxt);
                SelectLatestVersion();
                // debug - begin
                UPGDebugTable.DeleteAll();
                DebugCounter := 1;
                // debug - end
                if SQLImportType = SQLImportType::"AL" then
                    RestoreValues()
                else begin
                    SQLServerConnect();
                    if SQLRestoreFromSQLTable then
                        SQLTransferFromSQLUpgradeTable();
                    SQLRestoreValues();
                    if DeleteBufferTable then
                        SQLDropSQLUpgradeTable();
                end;
                if DeleteBufferTable then
                    UPGUpgradeTable.DeleteAll();
                Window.Close();
            end;

            trigger OnPostDataItem()
            var
                DoneMsg: Label '\\%1 - %2 = %3', Comment = 'DEA=%1 %2 %3';
            begin
                GlobalLanguage(CurrentLanguage);
                if SQLImportType = SQLImportType::"AL" then
                    Message(StepDoneMsg)
                else
                    Message(StepDoneMsg + StrSubstNo(DoneMsg, SQLTempStartTime, CurrentDateTime(), CurrentDateTime - SQLTempStartTime));
            end;

            trigger OnPreDataItem()
            begin
                if not Confirm(FillUpgradeTableQst, false) then
                    Error(UserErr);

                SQLTempStartTime := CurrentDateTime();

                CurrentLanguage := GlobalLanguage;
                GlobalLanguage(1033);
            end;
        }
    }

    requestpage
    {
        Caption = 'Fill Original Table (Step 2)';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(SQLImportTypeField; SQLImportType)
                    {
                        ApplicationArea = All;
                        Caption = 'Type of import';
                        ToolTip = 'Specify whether you want to import the data by SQL script (recommended) or by AL.';
                        OptionCaption = 'AL,SQL';

                        trigger OnValidate()
                        begin
                            SQLRestoreFromSQLTableEnabled := SQLImportType = SQLImportType::SQL;
                        end;
                    }

                    field(DeleteVal; DeleteBufferTable)
                    {
                        ApplicationArea = All;
                        Caption = 'Delete the backup table';
                        ToolTip = 'Place a checkmark here if the backup table should be deleted after the import.';
                    }
                    field(SQLRestoreFromSQLTableField; SQLRestoreFromSQLTable)
                    {
                        ApplicationArea = All;
                        Caption = 'Restore from separate SQL Table';
                        ToolTip = 'If the option is set, the stored data will be transferred from an SQL table that is independent of NAV/BC. For this, the data must have been transferred to this table in the first step.';
                        Enabled = SQLRestoreFromSQLTableEnabled;

                    }

                    field(SQLServerNameField; SQLServerName)
                    {
                        ApplicationArea = All;
                        Caption = 'SQL Server+Instance';
                        ToolTip = 'Specify the SQL Server and the instance.';
                        ShowMandatory = true;
                    }
                    field(SQLDatabaseNameField; SQLDatabaseName)
                    {
                        ApplicationArea = All;
                        Caption = 'SQL Database';
                        ToolTip = 'Specify the SQL Database.';
                        ShowMandatory = true;
                    }
                    field(SQLNTAuthentificationField; SQLNTAuthentification)
                    {
                        ApplicationArea = All;
                        Caption = 'NT Authentification';
                        ToolTip = 'Specify whether you want to use Windows authentication.';
                        ShowMandatory = true;

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
                        Editable = not SQLNTAuthentificationActivated;
                        ToolTip = 'Specifies the username.';
                        ShowMandatory = true;
                    }
                    field(SQLPasswordField; SQLPassword)
                    {
                        ApplicationArea = All;
                        Caption = 'Password';
                        Editable = not SQLNTAuthentificationActivated;
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password.';
                        ShowMandatory = true;
                    }
                    field(DebugField; DoDebug)
                    {
                        ApplicationArea = All;
                        Enabled = SQLRestoreFromSQLTableEnabled;
                        Caption = 'Debug Statements';
                        ToolTip = 'If this optin is set, the statements will be stored in T71501.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            SQLImportType := SQLImportType::SQL;
            if SQLNTAuthentification then begin
                SQLNTAuthentificationActivated := true;
                SQLUserID := '';
                SQLPassword := '';
            end else
                SQLNTAuthentificationActivated := false;
            SQLRestoreFromSQLTableEnabled := SQLImportType = SQLImportType::SQL;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SQLServerName := SQLGetServerInstanceName();
        SQLDatabaseName := SQLGetDatabaseName();
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
        SQLConnection: DotNet "UPG SqlConnectionNVX";
        Window: Dialog;
        SQLTempStartTime: DateTime;
        SQLDatabaseName: Text;
        SQLPassword: Text[100];
        SQLServerName: Text[100];
        SQLUserID: Text[100];
        SQLInvalidIdentifierChars: Code[10];
        CurrentLanguage: Integer;
        SQLImportType: Option "AL",SQL;
        DeleteBufferTable: Boolean;
        RecRefOpened: Boolean;
        SQLNTAuthentification: Boolean;
        [InDataSet]
        SQLNTAuthentificationActivated: Boolean;
        FillUpgradeTableQst: Label 'Would you like to fill the original tables from the backup? This step cannot be undone.';
        SQLRestoreFromSQLTable: Boolean;
        SQLUpgradeTableLbl: Label 'Upgrade Table';
        [InDataSet]
        SQLRestoreFromSQLTableEnabled: Boolean;
        SQLWindowDlgTxt: Label 'Restore\Company #1#############################\read #2#############################', Comment = 'DEA=%1 Rücksicherung/Firmen %2 lesen';
        UserErr: Label 'Cancel by user';
        StepDoneMsg: Label 'The Restore is done successfully.';
        WindowDlgTxt: Label 'Restore\Company #1#############################\read #2#############################\Total #3###############', Comment = 'DEA=%1 Rücksicherung/Firmen %2 lesen %3 Gesamt';
        DebugCounter: Integer;
        DoDebug: Boolean;

    local procedure RestoreValues()
    var
        UPGUpgradeTable: Record FRAUpgradeIndivFieldsNVX;
        UPGUpgradeTable2: Record FRAUpgradeIndivFieldsNVX;
        "Object": Record AllObjWithCaption;
        ImportRecRef: RecordRef;
        OldCompany: Text;
        OldEntry: Integer;
        OldTableId: Integer;
        IsInit: Boolean;
        IsStandardTable: Boolean;
        Skip: Boolean;
    begin
        UPGUpgradeTable.Reset();
        UPGUpgradeTable.SetCurrentKey("Company Name", "Table Number", "Entry Number", "Field Number");

        OldCompany := '<><><>';
        OldTableId := -9999;
        OldEntry := -9999;

        if not UPGUpgradeTable.FindSet() then
            exit;

        RecRefOpened := false;
        repeat
            // first check, if table exists
            if (UPGUpgradeTable."Company Name" <> OldCompany) or (UPGUpgradeTable."Table Number" <> OldTableId) then begin
                IsStandardTable := not IsTableInModul(UPGUpgradeTable."Table Number");
                if RecRefOpened then begin
                    ImportRecRef.Close();
                    RecRefOpened := false;
                end;
                Skip := false;
                OldEntry := -9999;
                if UPGUpgradeTable."Company Name" <> '' then
                    if not Company.Get(UPGUpgradeTable."Company Name") then
                        Skip := true;
                if not Skip then
                    if not Object.Get(Object."Object Type"::Table, UPGUpgradeTable."Table Number") then
                        Skip := true;
                if not Skip then begin
                    if UPGUpgradeTable."Company Name" <> '' then
                        ImportRecRef.Open(UPGUpgradeTable."Table Number", false, UPGUpgradeTable."Company Name")
                    else
                        ImportRecRef.Open(UPGUpgradeTable."Table Number");
                    OldCompany := UPGUpgradeTable."Company Name";
                    OldTableId := UPGUpgradeTable."Table Number";
                    RecRefOpened := true;
                    Window.Update(1, UPGUpgradeTable."Company Name");
                    Window.Update(2, ImportRecRef.Caption);
                end else begin
                    // goto last record in this block
                    UPGUpgradeTable.SetRange("Company Name", UPGUpgradeTable."Company Name");
                    UPGUpgradeTable.SetRange("Table Number", UPGUpgradeTable."Table Number");
                    UPGUpgradeTable.FindLast();
                    UPGUpgradeTable.SetRange("Company Name");
                    UPGUpgradeTable.SetRange("Table Number");
                end;
            end;
            if not Skip then
                if OldEntry <> UPGUpgradeTable."Entry Number" then begin
                    OldEntry := UPGUpgradeTable."Entry Number";
                    UPGUpgradeTable2.Reset();
                    UPGUpgradeTable2.SetCurrentKey("Company Name", "Table Number", "Entry Number", "Field Number");
                    UPGUpgradeTable2.SetRange("Company Name", UPGUpgradeTable."Company Name");
                    UPGUpgradeTable2.SetRange("Table Number", UPGUpgradeTable."Table Number");
                    UPGUpgradeTable2.SetRange("Entry Number", UPGUpgradeTable."Entry Number");
                    if IsStandardTable then begin
                        if UPGUpgradeTable2.FindFirst() then begin
                            ImportRecRef.SetPosition(UPGUpgradeTable2."Record Key");
                            // only if record still exists, update all values
                            if ImportRecRef.Get(ImportRecRef.RecordId) then begin
                                if UPGUpgradeTable2.FindSet() then
                                    repeat
                                        UpdateFieldValue(UPGUpgradeTable2, ImportRecRef);
                                    until UPGUpgradeTable2.Next() = 0;
                                ImportRecRef.Modify();
                            end;
                        end;
                    end else
                        // if is Upgrade table, restore all fields
                        if UPGUpgradeTable2.FindSet() then begin
                            // primary key is extended
                            if UPGUpgradeTable2."Table Number" = 60000 then
                                if StrPos(UPGUpgradeTable2."Record Key", 'Field6=0') = 0 then
                                    UPGUpgradeTable2."Record Key" := CopyStr(UPGUpgradeTable2."Record Key" + ',Field6=0()', 1, MaxStrLen(UPGUpgradeTable2."Record Key"));
                            ImportRecRef.SetPosition(UPGUpgradeTable2."Record Key");
                            IsInit := false;
                            if not ImportRecRef.Get(ImportRecRef.RecordId) then
                                IsInit := true;
                            if IsInit then
                                ImportRecRef.Init();
                            repeat
                                UpdateFieldValue(UPGUpgradeTable2, ImportRecRef);
                            until UPGUpgradeTable2.Next() = 0;
                            if IsInit then
                                ImportRecRef.Insert()
                            else
                                ImportRecRef.Modify();
                        end;
                    // goto last record of this entry
                    UPGUpgradeTable.SetRange("Company Name", UPGUpgradeTable."Company Name");
                    UPGUpgradeTable.SetRange("Table Number", UPGUpgradeTable."Table Number");
                    UPGUpgradeTable.SetRange("Entry Number", UPGUpgradeTable."Entry Number");
                    UPGUpgradeTable.FindLast();
                    UPGUpgradeTable.SetRange("Company Name");
                    UPGUpgradeTable.SetRange("Table Number");
                    UPGUpgradeTable.SetRange("Entry Number");
                end;
        until UPGUpgradeTable.Next() = 0;

        if RecRefOpened then
            ImportRecRef.Close();
    end;

    local procedure UpdateFieldValue(UPGUpgradeTable2: Record FRAUpgradeIndivFieldsNVX; var ImportRecRef: RecordRef)
    var
        FieldList: Record "Field";
        ImportFieldRef: FieldRef;
        DummyDateForm: DateFormula;
        DummyGUID: Guid;
    begin
        clear(DummyGUID);
        Clear(DummyDateForm);
        if not FieldList.Get(UPGUpgradeTable2."Table Number", UPGUpgradeTable2."Field Number") then
            exit;
        if FieldList.ObsoleteState <> FieldList.ObsoleteState::No then
            exit;
        if not FieldList.Enabled then
            exit;
        if FieldList.Class <> FieldList.Class::Normal then
            exit;
        ImportFieldRef := ImportRecRef.Field(UPGUpgradeTable2."Field Number");
        case FieldList.Type of
            FieldList.Type::Integer,
            FieldList.Type::Option,
            FieldList.Type::BigInteger:
                ImportFieldRef.Value(UPGUpgradeTable2."Value as BigInteger");
            FieldList.Type::Decimal:
                ImportFieldRef.Value(UPGUpgradeTable2."Value as Decimal");
            FieldList.Type::Date:
                ImportFieldRef.Value(UPGUpgradeTable2."Value as Date");
            FieldList.Type::Time:
                ImportFieldRef.Value(UPGUpgradeTable2."Value as Time");
            FieldList.Type::DateTime:
                ImportFieldRef.Value(UPGUpgradeTable2."Value as DateTime");
            FieldList.Type::Boolean:
                ImportFieldRef.Value(UPGUpgradeTable2."Value as Boolean");
            FieldList.Type::GUID:
                begin
                    if Evaluate(DummyGUID, UPGUpgradeTable2."Value as Text") then;
                    ImportFieldRef.Value(DummyGUID);
                end;
            FieldList.Type::DateFormula:
                begin
                    if Evaluate(DummyDateForm, UPGUpgradeTable2."Value as Text") then;
                    ImportFieldRef.Value(DummyDateForm);
                end;
            else
                ImportFieldRef.Value(UPGUpgradeTable2."Value as Text");
        end; // End Case
    end;


    local procedure SQLRestoreValues()
    var
        TempCompany: Record Company temporary;
        TempField: Record "Field" temporary;
        DataReader: DotNet "UPG SqlDataReaderNVX";
        SqlCommand: DotNet "UPG SqlCommandNVX";
    begin
        SqlCommand := SQLConnection.CreateCommand();
        SqlCommand.CommandTimeout := 0;
        SqlCommand.CommandText(StrSubstNo('select distinct [Company Name] FROM [%1] WITH (READUNCOMMITTED) ORDER BY [Company Name]', SQLGetTableName('UPG Upgrade Table', 'Company Name')));
        DataReader := SqlCommand.ExecuteReader();
        while DataReader.Read() do begin
            TempCompany.Name := DataReader.GetString(0);
            TempCompany.Insert();
        end;
        DataReader.Close();

        if TempCompany.FindSet(false) then
            repeat
                SqlCommand.CommandText(StrSubstNo('select distinct [Table Number], [Field Number] FROM [%1] WITH (READUNCOMMITTED) WHERE [Company Name]=''%2'' ORDER BY [Table Number], [Field Number]',
                    SQLGetTableName('UPG Upgrade Table', 'Company Name'), TempCompany.Name));
                DataReader := SqlCommand.ExecuteReader();
                while DataReader.Read() do begin
                    TempField.TableNo := DataReader.GetInt32(0);
                    TempField."No." := DataReader.GetInt32(1);
                    TempField.Insert();
                end;
                DataReader.Close();
                if TempField.FindSet() then
                    repeat
                        Window.Update(1, TempCompany.Name);
                        if not IsTableInModul(TempField.TableNo) then
                            SQLRestoreOneField(TempCompany.Name, TempField.TableNo, TempField."No.")
                        else begin
                            SQLRestoreModulTable(TempCompany.Name, TempField.TableNo);
                            // skip all further fields
                            TempField.SetRange(TableNo, TempField.TableNo);
                            TempField.DeleteAll();
                            TempField.SetRange(TableNo);
                        end;
                    until TempField.Next() = 0;
                TempField.DeleteAll();
            until TempCompany.Next() = 0;

        DataReader.Dispose();
        SqlCommand.Dispose();

        SelectLatestVersion();
    end;

    local procedure SQLRestoreOneField(UseCompanyName: Text; TableID: Integer; FieldID: Integer)
    var
        ExportFields: Record "Field";
        KeyRecRef: RecordRef;
        RecRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        KeyFieldsFilter: Text;
        RecordKeyPart: Text;
        SourceFieldName: Text;
        SQLStmt: Text;
        SQLTableName: Text;
        i: Integer;
    begin
        // restore a field in a standard table
        KeyFieldsFilter := '';

        Clear(KeyRecRef);
        KeyRecRef.Open(TableID, true);
        Window.Update(2, KeyRecRef.Caption);
        PrimaryKeyRef := KeyRecRef.KeyIndex(1);

        // if it is not Modul table, skip primary key fields
        for i := 1 to PrimaryKeyRef.FieldCount do
            if (not IsTableInModul(TableID)) and (PrimaryKeyRef.FieldIndex(i).Number = FieldID) then begin
                KeyRecRef.Close();
                exit;
            end;

        for i := 1 to PrimaryKeyRef.FieldCount do begin
            if RecordKeyPart <> '' then
                RecordKeyPart += ',';
            RecordKeyPart += StrSubstNo('Field%1=0(''+CONVERT(NVARCHAR(MAX),[%2])+'')', Format(PrimaryKeyRef.FieldIndex(i).Number), SQLReplaceInvalidChars(PrimaryKeyRef.FieldIndex(i).Name));
        end;
        RecordKeyPart := 'N''' + RecordKeyPart + '''';
        KeyRecRef.Close();

        Clear(RecRef);

        if UseCompanyName <> '' then
            RecRef.Open(TableID, false, UseCompanyName)
        else
            RecRef.Open(TableID);

        ExportFields.Reset();
        ExportFields.SetRange(TableNo, TableID);
        ExportFields.SetRange("No.", FieldID);
        ExportFields.SetRange(Enabled, true);
        ExportFields.SetRange(Class, ExportFields.Class::Normal);
        ExportFields.SetRange(ObsoleteState, ExportFields.ObsoleteState::No);
        ExportFields.SetFilter(Type, '<>%1', ExportFields.Type::BLOB);
        if ExportFields.FindFirst() then begin

            Window.Update(2, RecRef.Caption);

            //SourceFieldName
            case ExportFields.Type of
                ExportFields.Type::Text, ExportFields.Type::Code, ExportFields.Type::DateFormula, ExportFields.Type::GUID:
                    SourceFieldName := '[Value as Text]';
                ExportFields.Type::Integer, ExportFields.Type::Option, ExportFields.Type::BigInteger:
                    SourceFieldName := '[Value as BigInteger]';
                ExportFields.Type::DateTime:
                    SourceFieldName := '[Value as DateTime]';
                ExportFields.Type::Boolean:
                    SourceFieldName := '[Value as Boolean]';
                ExportFields.Type::Decimal:
                    SourceFieldName := '[Value as Decimal]';
                ExportFields.Type::Time:
                    SourceFieldName := '[Value as Time]';
                ExportFields.Type::Date:
                    SourceFieldName := '[Value as Date]';
                else
                    SourceFieldName := '[Value as Text]';
            end;

            if UseCompanyName <> '' then
                SQLTableName := StrSubstNo('%1$%2', SQLReplaceInvalidChars(UseCompanyName), SQLReplaceInvalidChars(RecRef.Name))
            else
                SQLTableName := StrSubstNo('%1', SQLReplaceInvalidChars(RecRef.Name));

            SQLStmt += StrSubstNo('UPDATE t1 SET [%1]=t2.' + SourceFieldName + ' ', SQLReplaceInvalidChars(ExportFields.FieldName));
            SQLStmt += StrSubstNo('FROM [%1] t1 ', SQLGetTableName(SQLTableName, ExportFields.FieldName));
            SQLStmt += StrSubstNo('INNER JOIN [%1] t2 WITH (READUNCOMMITTED) ', SQLGetTableName('UPG Upgrade Table', 'Company Name'));
            SQLStmt += StrSubstNo('ON [Company Name]=''%1'' and [Table Number] = %2 and [Field Number] = %3 and [Record Key] = %4', UseCompanyName, TableID, FieldID, RecordKeyPart);

            SQLSendSQLStatement(SQLStmt);

        end;
        RecRef.Close();
    end;

    local procedure SQLRestoreModulTable(UseCompanyName: Text; TableID: Integer)
    var
        ExportFields: Record "Field";
        KeyRecRef: RecordRef;
        RecRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        EmptyValuePart: Text;
        InsertPart: Text;
        KeyFieldsFilter: Text;
        RecordKeyPart: Text;
        SourceFieldname: Text;
        SQLStmt: Text;
        SQLTableName: Text;
        SubPart: Text;
        i: Integer;
    begin
        // fill Modul table with one sql command

        KeyFieldsFilter := '';

        Clear(KeyRecRef);
        KeyRecRef.Open(TableID, true);
        Window.Update(2, KeyRecRef.Caption);
        PrimaryKeyRef := KeyRecRef.KeyIndex(1);

        for i := 1 to PrimaryKeyRef.FieldCount do begin
            if RecordKeyPart <> '' then
                RecordKeyPart += ',';
            RecordKeyPart += StrSubstNo('Field%1=0(''+CONVERT(NVARCHAR(MAX),[%2])+'')', Format(PrimaryKeyRef.FieldIndex(i).Number), SQLReplaceInvalidChars(PrimaryKeyRef.FieldIndex(i).Name));
        end;
        RecordKeyPart := 'N''' + RecordKeyPart + '''';
        KeyRecRef.Close();

        Clear(RecRef);

        if UseCompanyName <> '' then
            RecRef.Open(TableID, false, UseCompanyName)
        else
            RecRef.Open(TableID);

        ExportFields.Reset();
        ExportFields.SetCurrentKey(TableNo, "No.");
        ExportFields.SetRange(TableNo, TableID);
        ExportFields.SetRange(Enabled, true);
        ExportFields.SetRange(Class, ExportFields.Class::Normal);
        ExportFields.SetFilter(Type, '<>%1', ExportFields.Type::BLOB);
        if ExportFields.FindFirst() then begin

            Window.Update(2, RecRef.Caption);

            if UseCompanyName <> '' then
                SQLTableName := StrSubstNo('%1$%2', SQLReplaceInvalidChars(UseCompanyName), SQLReplaceInvalidChars(RecRef.Name))
            else
                SQLTableName := StrSubstNo('%1', SQLReplaceInvalidChars(RecRef.Name));

            SQLTableName := SQLGetModulTablename(SQLTableName);

            SQLStmt += StrSubstNo(';WITH SUB AS (select DISTINCT [Entry Number],[Record Key] FROM [%1] WITH (READUNCOMMITTED) WHERE [Company Name]=''%2'' AND [Table Number] = %3) ',
                SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name'), UseCompanyName, TableID);

            if ExportFields.FindSet() then
                repeat
                    if SQLFieldExists(SQLTableName, ExportFields.FieldName) then begin
                        case ExportFields.Type of
                            ExportFields.Type::Integer, ExportFields.Type::Option, ExportFields.Type::Boolean, ExportFields.Type::BigInteger:
                                EmptyValuePart := '0';
                            ExportFields.Type::Decimal:
                                EmptyValuePart := '''0''';
                            ExportFields.Type::Text, ExportFields.Type::Code, ExportFields.Type::DateFormula:
                                EmptyValuePart := '''''';
                            ExportFields.Type::Date, ExportFields.Type::Time, ExportFields.Type::DateTime:
                                EmptyValuePart := '''01-01-1753''';
                            ExportFields.Type::GUID:
                                if ExportFields.FieldName = '$systemId' then
                                    EmptyValuePart := 'NEWID()'
                                else
                                    EmptyValuePart := '''00000000-0000-0000-0000-000000000000''';
                            else
                                EmptyValuePart := '''''';
                        end;

                        //SourceFieldName
                        case ExportFields.Type of
                            ExportFields.Type::Text, ExportFields.Type::Code, ExportFields.Type::DateFormula, ExportFields.Type::GUID:
                                SourceFieldname := '[Value as Text]';
                            ExportFields.Type::Integer, ExportFields.Type::Option, ExportFields.Type::BigInteger:
                                SourceFieldname := '[Value as BigInteger]';
                            ExportFields.Type::DateTime:
                                SourceFieldname := '[Value as DateTime]';
                            ExportFields.Type::Boolean:
                                SourceFieldname := '[Value as Boolean]';
                            ExportFields.Type::Decimal:
                                SourceFieldname := '[Value as Decimal]';
                            ExportFields.Type::Time:
                                SourceFieldname := '[Value as Time]';
                            ExportFields.Type::Date:
                                SourceFieldname := '[Value as Date]';
                            else
                                SourceFieldname := '[Value as Text]';
                        end;

                        if SubPart <> '' then
                            SubPart += ', ';
                        if ExportFields.ObsoleteState = ExportFields.ObsoleteState::No then
                            SubPart += StrSubstNo('COALESCE((SELECT ' + SourceFieldname + ' FROM [%1] t2 WITH (READUNCOMMITTED) WHERE [Company Name]=''%2'' AND ' +
                                                                        '[Table Number] = %3 AND t2.[Entry Number]=SUB.[Entry Number] AND [Field Number] = %4),%6) [%5]',
                                                    SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name'), UseCompanyName, TableID, ExportFields."No.", ExportFields.FieldName, EmptyValuePart)
                        else
                            SubPart += StrSubstNo('%1 [%2]', EmptyValuePart, ExportFields.FieldName);
                        if InsertPart <> '' then
                            InsertPart += ',';
                        InsertPart += '[' + SQLReplaceInvalidChars(ExportFields.FieldName) + ']';
                    end;
                until ExportFields.Next() = 0;

            SQLStmt += StrSubstNo('INSERT INTO [%1](%2) ', SQLTableName, InsertPart);
            SQLStmt += 'SELECT ';
            SQLStmt += SubPart;
            SQLStmt += 'FROM SUB ';
            // activate next line to ignore existing records. Otherwise there will be errors, if any Modul table is not empty
            SQLStmt += STRSUBSTNO('WHERE NOT EXISTS(SELECT * FROM [%1] WHERE %2 = SUB.[Record Key]) ', SQLTableName, RecordKeyPart);

            SQLSendSQLStatement(SQLStmt);

        end;
        RecRef.Close();
    end;

    procedure SQLServerConnect() Result: Boolean
    var
        SqlConnectionState: DotNet "UPG ConnectionStateNVX";
        ConnectionString: Text[250];
        SQLConnectionOK: Boolean;
        InvalidConnectionErr: Label 'The SQL Connection information specified is incorrect. Please verify the User ID and Password.';
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
        SQLCommand: DotNet "UPG SqlCommandNVX";
        SqlConnectionState: DotNet "UPG ConnectionStateNVX";
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
        XmlDocument: DotNet XmlDocument;
        XmlNode: DotNet XmlNode;
        Value: Text;
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
        XmlAttribute: DotNet XmlAttribute;
        XmlDocument: DotNet XmlDocument;
        XmlNode: DotNet XmlNode;
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
        Registry: DotNet "UPG RegistryNVX";
        ImagePath: Text;
        InstanceName: Text;
        InstanceSettingsFile: Text;
        RegistryKey: Text;
        SplitPos: Integer;
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

        SqlCommand.Dispose();
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

    local procedure SQLGetTableName(TableName2: Text; FieldName2: Text) Result: Text
    var
        NAVApp: Record "NAV App Installed App";
        DataReader: DotNet "UPG SqlDataReaderNVX";
        SqlCommand: DotNet "UPG SqlCommandNVX";
    begin
        // detect via tablename and fieldname in which SQL Table the field is (Extensions)
        Result := SQLReplaceInvalidChars(TableName2);

        // if no extension is installed, return tablename
        if NAVApp.IsEmpty then
            exit(Result);

        // check the table of the field,if extensions are installed
        SqlCommand := SQLConnection.CreateCommand();
        SqlCommand.CommandText(StrSubstNo('select t.name from sys.syscolumns c INNER JOIN sys.tables t ON t.[object_id] = c.id ' +
            'where (t.name = ''%1'' or t.name like ''%1$%'') AND c.name = ''%2''',
            SQLReplaceInvalidChars(TableName2), SQLReplaceInvalidChars(FieldName2)));
        DataReader := SqlCommand.ExecuteReader();
        if DataReader.Read() then
            Result := DataReader.GetString(0);
        DataReader.Dispose();
        SqlCommand.Dispose();
    end;

    local procedure IsTableInModul(TableID: Integer): Boolean
    begin
        // Is Modul table? General interesting
        // if TableID in [1000000..2000000] then
        //     exit(true);
        exit(false);
    end;

    local procedure SQLGetFrauscherBaseAppExtension() Result: Text
    var
        NAVApp: Record "NAV App Installed App";
    begin
        // detect APP ID of Frauscher Base extension
        NAVApp.SetRange(Name, 'Frauscher Base');
        if NAVApp.FindFirst() then
            Result := DelChr(LowerCase(NAVApp."App ID"), '=', '{}');
    end;

    local procedure SQLGetModulTablename(TableName2: Text) Result: Text
    begin
        // detect SQL Name of Frauscher Base Table (even if it is extension)
        Result := SQLReplaceInvalidChars(TableName2);
        if SQLGetFrauscherBaseAppExtension() <> '' then
            Result += '$' + SQLGetFrauscherBaseAppExtension();
    end;

    local procedure SQLFieldExists(TableName2: Text; FieldName2: Text) Result: Boolean
    var
        NAVApp: Record "NAV App Published App";
        DataReader: DotNet "UPG SqlDataReaderNVX";
        SqlCommand: DotNet "UPG SqlCommandNVX";
    begin
        // check,if the field exists in SQL table, there might be extensions of Modul tables with fields, which are not in the Modul SQL table
        Result := false;

        // if no app is installed, return TRUE
        //if NAVApp.IsEmpty() then
        //    exit(true);

        // check the table,if an extension is installed
        SqlCommand := SQLConnection.CreateCommand();
        SqlCommand.CommandText(StrSubstNo('select t.name from sys.syscolumns c INNER JOIN sys.tables t ON t.[object_id] = c.id where (t.name = ''%1'') AND c.name = ''%2''',
            SQLReplaceInvalidChars(TableName2), SQLReplaceInvalidChars(FieldName2)));
        DataReader := SqlCommand.ExecuteReader();
        Result := DataReader.HasRows();
        DataReader.Dispose();
        SqlCommand.Dispose();
    end;

    local procedure SQLTransferFromSQLUpgradeTable()
    var
        Statement: Text;
    begin
        Statement := StrSubstNo('TRUNCATE TABLE [%1]', SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name'));

        SQLSendSQLStatement(Statement);

        Statement := StrSubstNo('INSERT INTO [dbo].[%1] ', SQLGetTableName('FRAUpgradeIndivFieldsNVX', 'Company Name'));
        Statement += '([Company Name],[Table Number],[Entry Number],[Field Number],[Field Type],[Value as Text],[Record Key],[Value as BigInteger],[Value as DateTime],[Value as Boolean],[Value as Decimal],[Value as Time],[Value as Date]) ';
        Statement += 'SELECT [Company Name],[Table Number],[Entry Number],[Field Number],[Field Type],[Value as Text],[Record Key],[Value as BigInteger],[Value as DateTime],[Value as Boolean],[Value as Decimal],[Value as Time],[Value as Date] ';
        Statement += StrSubstNo('FROM [%1] WITH (READUNCOMMITTED)', SQLUpgradeTableLbl);

        SQLSendSQLStatement(Statement);
    end;

    local procedure SQLDropSQLUpgradeTable()
    var
        Statement: Text;
    begin
        Statement := StrSubstNo('IF EXISTS(SELECT * FROM sys.tables where Name = ''%1'') DROP TABLE [%1] ', SQLUpgradeTableLbl);

        SQLSendSQLStatement(Statement);
        SQLServerDisconnect();
    end;

}