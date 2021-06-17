{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit khonfirebaselaz;

{$warn 5023 off : no warning about unused units}
interface

uses
  Firebaselazu, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('Firebaselazu', @Firebaselazu.Register);
end;

initialization
  RegisterPackage('khonfirebaselaz', @Register);
end.
