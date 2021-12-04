pageextension 60000 "FRACompanyInfoExtNVX" extends "Company Information"
{
    actions
    {
        addafter(Codes)
        {
            group(CopyDataToExtension)
            {
                Caption = 'Copy Data to Extensiontables', Comment = 'DEA="Daten kopieren in den Erweiterungstabellen"';
                action(Copy)
                {
                    Caption = 'Start', Comment = 'DEA="Starten"';
                    Image = Copy;
                    RunObject = report FRAFillUpgradeTablesStep1NVX;
                }
            }
        }
    }
}