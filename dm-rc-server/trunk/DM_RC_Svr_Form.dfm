object CfgForm: TCfgForm
  Left = 469
  Top = 185
  Width = 466
  Height = 359
  Caption = 'CfgForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object PC1: TPageControl
    Left = 8
    Top = 8
    Width = 441
    Height = 257
    ActivePage = TS1
    TabOrder = 0
    object TS1: TTabSheet
      Caption = 'General'
      object Label1: TLabel
        Left = 168
        Top = 0
        Width = 52
        Height = 13
        Caption = 'Connected'
      end
      object RG1: TRadioGroup
        Left = 0
        Top = 0
        Width = 81
        Height = 49
        Caption = ' Control '
        ItemIndex = 0
        Items.Strings = (
          'Local'
          'Remote')
        TabOrder = 0
      end
      object LB_IP: TListBox
        Left = 0
        Top = 56
        Width = 161
        Height = 81
        Enabled = False
        ItemHeight = 13
        MultiSelect = True
        TabOrder = 1
      end
      object Button1: TButton
        Left = 0
        Top = 144
        Width = 161
        Height = 25
        Caption = 'Get Local IP List'
        Enabled = False
        TabOrder = 2
        OnClick = Button1Click
      end
      object LE_Port: TLabeledEdit
        Left = 88
        Top = 24
        Width = 73
        Height = 21
        EditLabel.Width = 19
        EditLabel.Height = 13
        EditLabel.Caption = 'Port'
        TabOrder = 3
      end
      object LB_Connected: TListBox
        Left = 168
        Top = 16
        Width = 145
        Height = 121
        ItemHeight = 13
        TabOrder = 4
      end
      object Button2: TButton
        Left = 200
        Top = 144
        Width = 75
        Height = 25
        Caption = 'Refresh'
        TabOrder = 5
        OnClick = Button2Click
      end
    end
  end
  object BitBtn1: TBitBtn
    Left = 80
    Top = 280
    Width = 75
    Height = 25
    TabOrder = 1
    OnClick = BitBtn1Click
    Kind = bkOK
  end
  object BitBtn2: TBitBtn
    Left = 208
    Top = 280
    Width = 75
    Height = 25
    TabOrder = 2
    OnClick = BitBtn2Click
    Kind = bkCancel
  end
end
