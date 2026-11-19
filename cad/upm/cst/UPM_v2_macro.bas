' UPM v2 - macro generada por gen_cst_macro.py (no editar a mano)
' Uso: proyecto CST nuevo y vacío -> Macros > Run Macro... -> este archivo.
' Crea los parámetros y añade cada paso al History List.

Option Explicit

Sub Main ()
    Dim s As String

    StoreParameter "Lwg", "68.24"
    StoreParameter "Wbody", "40"
    StoreParameter "Hhalf", "6"
    StoreParameter "aWR", "1.651"
    StoreParameter "bWR", "0.82"
    StoreParameter "zpart", "bWR/2"
    StoreParameter "Lcav", "63"
    StoreParameter "Wcav", "9.997"
    StoreParameter "dpin", "0.4"
    StoreParameter "hpin", "0.77"
    StoreParameter "ppin", "0.8"
    StoreParameter "y1pin", "aWR/2+dpin/2"
    StoreParameter "x0pin", "-Lcav/2+0.3"
    StoreParameter "tpl", "0"
    StoreParameter "tboss", "0.508"
    StoreParameter "Rboss", "4.7625"
    StoreParameter "tdisc", "7.112"
    StoreParameter "Rdisc", "9.525"
    StoreParameter "BCfl", "14.2875"
    StoreParameter "r45", "5.051394"
    StoreParameter "dtap", "2.2606"
    StoreParameter "ltap", "6"
    StoreParameter "dcb", "3.556"
    StoreParameter "lcb", "1.016"
    StoreParameter "dpst", "1.5875"
    StoreParameter "dprc", "1.638"
    StoreParameter "lal", "3"
    StoreParameter "chir", "1"
    StoreParameter "xm3", "11.5"
    StoreParameter "ym3", "11.45"
    StoreParameter "dm3", "3.4"
    StoreParameter "hexS", "5.7"
    StoreParameter "hexH", "2.6"
    StoreParameter "xab", "17.25"
    StoreParameter "yab", "7.8"
    StoreParameter "dpress", "2.95"
    StoreParameter "dslip", "3.05"
    StoreParameter "lab", "5"
    StoreParameter "slotL", "0.3"

    ' 01 - use template: WG6_Pins (UPM v2)
    s = ""
    s = s & "With Units" & vbCrLf
    s = s & "     .SetUnit ""Length"", ""mm""" & vbCrLf
    s = s & "     .SetUnit ""Frequency"", ""GHz""" & vbCrLf
    s = s & "     .SetUnit ""Voltage"", ""V""" & vbCrLf
    s = s & "     .SetUnit ""Resistance"", ""Ohm""" & vbCrLf
    s = s & "     .SetUnit ""Inductance"", ""nH""" & vbCrLf
    s = s & "     .SetUnit ""Temperature"",  ""degC""" & vbCrLf
    s = s & "     .SetUnit ""Time"", ""ns""" & vbCrLf
    s = s & "     .SetUnit ""Current"", ""A""" & vbCrLf
    s = s & "     .SetUnit ""Conductance"", ""S""" & vbCrLf
    s = s & "     .SetUnit ""Capacitance"", ""pF""" & vbCrLf
    s = s & "End With" & vbCrLf
    s = s & "ThermalSolver.AmbientTemperature ""0""" & vbCrLf
    s = s & "Solver.FrequencyRange ""110"", ""170""" & vbCrLf
    s = s & "Plot.DrawBox True" & vbCrLf
    s = s & "With Background" & vbCrLf
    s = s & "     .Type ""Normal""" & vbCrLf
    s = s & "     .Epsilon ""1.0""" & vbCrLf
    s = s & "     .Mu ""1.0""" & vbCrLf
    s = s & "     .XminSpace ""0.0""" & vbCrLf
    s = s & "     .XmaxSpace ""0.0""" & vbCrLf
    s = s & "     .YminSpace ""0.0""" & vbCrLf
    s = s & "     .YmaxSpace ""0.0""" & vbCrLf
    s = s & "     .ZminSpace ""0.0""" & vbCrLf
    s = s & "     .ZmaxSpace ""0.0""" & vbCrLf
    s = s & "End With" & vbCrLf
    s = s & "With Boundary" & vbCrLf
    s = s & "     .Xmin ""expanded open""" & vbCrLf
    s = s & "     .Xmax ""expanded open""" & vbCrLf
    s = s & "     .Ymin ""expanded open""" & vbCrLf
    s = s & "     .Ymax ""expanded open""" & vbCrLf
    s = s & "     .Zmin ""expanded open""" & vbCrLf
    s = s & "     .Zmax ""expanded open""" & vbCrLf
    s = s & "     .Xsymmetry ""none""" & vbCrLf
    s = s & "     .Ysymmetry ""none""" & vbCrLf
    s = s & "     .Zsymmetry ""none""" & vbCrLf
    s = s & "End With" & vbCrLf
    s = s & "FDSolver.ExtrudeOpenBC ""True""" & vbCrLf
    s = s & "Mesh.FPBAAvoidNonRegUnite ""True""" & vbCrLf
    s = s & "Mesh.ConsiderSpaceForLowerMeshLimit ""False""" & vbCrLf
    s = s & "Mesh.MinimumStepNumber ""5""" & vbCrLf
    s = s & "With MeshSettings" & vbCrLf
    s = s & "     .SetMeshType ""Hex""" & vbCrLf
    s = s & "     .Set ""RatioLimitGeometry"", ""20""" & vbCrLf
    s = s & "End With" & vbCrLf
    s = s & "With MeshSettings" & vbCrLf
    s = s & "     .SetMeshType ""HexTLM""" & vbCrLf
    s = s & "     .Set ""RatioLimitGeometry"", ""20""" & vbCrLf
    s = s & "End With" & vbCrLf
    s = s & "PostProcess1D.ActivateOperation ""vswr"", ""true""" & vbCrLf
    s = s & "PostProcess1D.ActivateOperation ""yz-matrices"", ""true""" & vbCrLf
    s = s & "With MeshSettings" & vbCrLf
    s = s & "     .SetMeshType ""Hex""" & vbCrLf
    s = s & "     .Set ""Version"", 1%" & vbCrLf
    s = s & "End With" & vbCrLf
    s = s & "With Mesh" & vbCrLf
    s = s & "     .MeshType ""PBA""" & vbCrLf
    s = s & "End With" & vbCrLf
    s = s & "ChangeSolverType(""HF Time Domain"")" & vbCrLf
    AddToHistory "use template: WG6_Pins (UPM v2)", s

    ' 02 - define material: Ni_plated
    s = ""
    s = s & "With Material" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Ni_plated""" & vbCrLf
    s = s & "     .Folder """"" & vbCrLf
    s = s & "     .FrqType ""all""" & vbCrLf
    s = s & "     .Type ""Lossy metal""" & vbCrLf
    s = s & "     .SetMaterialUnit ""GHz"", ""mm""" & vbCrLf
    s = s & "     .Mu ""1""" & vbCrLf
    s = s & "     .Kappa ""1.44e7""" & vbCrLf
    s = s & "     .Colour ""0"", ""0.501961"", ""0.25098""" & vbCrLf
    s = s & "     .Wireframe ""False""" & vbCrLf
    s = s & "     .Transparency ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define material: Ni_plated", s

    ' 03 - define material: Cu_plated
    s = ""
    s = s & "With Material" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Cu_plated""" & vbCrLf
    s = s & "     .Folder """"" & vbCrLf
    s = s & "     .FrqType ""all""" & vbCrLf
    s = s & "     .Type ""Lossy metal""" & vbCrLf
    s = s & "     .SetMaterialUnit ""GHz"", ""mm""" & vbCrLf
    s = s & "     .Mu ""1""" & vbCrLf
    s = s & "     .Kappa ""5.8e7""" & vbCrLf
    s = s & "     .Colour ""1"", ""0.52"", ""0.2""" & vbCrLf
    s = s & "     .Wireframe ""False""" & vbCrLf
    s = s & "     .Transparency ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define material: Cu_plated", s

    ' 04 - new component: Base
    s = ""
    s = s & "Component.New ""Base""" & vbCrLf
    AddToHistory "new component: Base", s

    ' 05 - new component: Tapa
    s = ""
    s = s & "Component.New ""Tapa""" & vbCrLf
    AddToHistory "new component: Tapa", s

    ' 06 - define brick: Base:mono
    s = ""
    s = s & "With Brick" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""mono""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .Xrange ""-Lwg/2+tboss"", ""Lwg/2-tboss""" & vbCrLf
    s = s & "     .Yrange ""-Wbody/2"", ""Wbody/2""" & vbCrLf
    s = s & "     .Zrange ""(zpart-Hhalf)"", ""(zpart+Hhalf)""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define brick: Base:mono", s

    ' 07 - define cylinder: Base:discL
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""discL""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""Rdisc""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)"", ""(-Lwg/2+tboss)+tdisc""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""0""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:discL", s

    ' 08 - define cylinder: Base:discR
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""discR""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""Rdisc""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""Lwg/2-tboss-tdisc"", ""Lwg/2-tboss""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""0""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:discR", s

    ' 09 - define cylinder: Base:bossL
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""bossL""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""Rboss""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""-Lwg/2"", ""(-Lwg/2+tboss)""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""0""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:bossL", s

    ' 10 - define cylinder: Base:bossR
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""bossR""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""Rboss""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""Lwg/2-tboss"", ""Lwg/2""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""0""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:bossR", s

    ' 11 - boolean add shapes: Base:mono, Base:discL
    s = ""
    s = s & "Solid.Add ""Base:mono"", ""Base:discL""" & vbCrLf
    AddToHistory "boolean add shapes: Base:mono, Base:discL", s

    ' 12 - boolean add shapes: Base:mono, Base:discR
    s = ""
    s = s & "Solid.Add ""Base:mono"", ""Base:discR""" & vbCrLf
    AddToHistory "boolean add shapes: Base:mono, Base:discR", s

    ' 13 - boolean add shapes: Base:mono, Base:bossL
    s = ""
    s = s & "Solid.Add ""Base:mono"", ""Base:bossL""" & vbCrLf
    AddToHistory "boolean add shapes: Base:mono, Base:bossL", s

    ' 14 - boolean add shapes: Base:mono, Base:bossR
    s = ""
    s = s & "Solid.Add ""Base:mono"", ""Base:bossR""" & vbCrLf
    AddToHistory "boolean add shapes: Base:mono, Base:bossR", s

    ' 15 - define brick: Base:cav
    s = ""
    s = s & "With Brick" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""cav""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .Xrange ""-Lcav/2"", ""Lcav/2""" & vbCrLf
    s = s & "     .Yrange ""-Wcav/2-tpl"", ""Wcav/2+tpl""" & vbCrLf
    s = s & "     .Zrange ""-bWR/2"", ""bWR/2""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define brick: Base:cav", s

    ' 16 - boolean subtract shapes: Base:mono, Base:cav
    s = ""
    s = s & "Solid.Subtract ""Base:mono"", ""Base:cav""" & vbCrLf
    AddToHistory "boolean subtract shapes: Base:mono, Base:cav", s

    ' 17 - define brick: Base:chan
    s = ""
    s = s & "With Brick" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""chan""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .Xrange ""-Lwg/2-0.1"", ""Lwg/2+0.1""" & vbCrLf
    s = s & "     .Yrange ""-aWR/2-tpl"", ""aWR/2+tpl""" & vbCrLf
    s = s & "     .Zrange ""-bWR/2"", ""bWR/2""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define brick: Base:chan", s

    ' 18 - boolean subtract shapes: Base:mono, Base:chan
    s = ""
    s = s & "Solid.Subtract ""Base:mono"", ""Base:chan""" & vbCrLf
    AddToHistory "boolean subtract shapes: Base:mono, Base:chan", s

    ' 19 - define cylinder: Base:pins
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""pins""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dpin/2-tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""z""" & vbCrLf
    s = s & "     .Zrange ""-bWR/2-0.01"", ""-bWR/2+hpin""" & vbCrLf
    s = s & "     .Xcenter ""x0pin""" & vbCrLf
    s = s & "     .Ycenter ""y1pin""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:pins", s

    ' 20 - transform: translate Base:pins
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Base:pins""" & vbCrLf
    s = s & "     .Vector ""0"", ""ppin"", ""0""" & vbCrLf
    s = s & "     .UsePickedPoints ""False""" & vbCrLf
    s = s & "     .InvertPickedPoints ""False""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""1""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Translate""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: translate Base:pins", s

    ' 21 - transform: mirror Base:pins
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Base:pins""" & vbCrLf
    s = s & "     .Origin ""Free""" & vbCrLf
    s = s & "     .Center ""0"", ""0"", ""0""" & vbCrLf
    s = s & "     .PlaneNormal ""0"", ""1"", ""0""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""1""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Mirror""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: mirror Base:pins", s

    ' 22 - transform: translate Base:pins
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Base:pins""" & vbCrLf
    s = s & "     .Vector ""ppin"", ""0"", ""0""" & vbCrLf
    s = s & "     .UsePickedPoints ""False""" & vbCrLf
    s = s & "     .InvertPickedPoints ""False""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""78""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Translate""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: translate Base:pins", s

    ' 23 - boolean add shapes: Base:mono, Base:pins
    s = ""
    s = s & "Solid.Add ""Base:mono"", ""Base:pins""" & vbCrLf
    AddToHistory "boolean add shapes: Base:mono, Base:pins", s

    ' 24 - define cylinder: Base:fl
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""fl""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dcb/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+lcb""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""BCfl/2""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:fl", s

    ' 25 - define cylinder: Base:cbB
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""cbB""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dcb/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+lcb""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""-BCfl/2""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:cbB", s

    ' 26 - boolean add shapes: Base:fl, Base:cbB
    s = ""
    s = s & "Solid.Add ""Base:fl"", ""Base:cbB""" & vbCrLf
    AddToHistory "boolean add shapes: Base:fl, Base:cbB", s

    ' 27 - define cylinder: Base:tpT
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""tpT""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dtap/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+ltap""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""BCfl/2""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:tpT", s

    ' 28 - boolean add shapes: Base:fl, Base:tpT
    s = ""
    s = s & "Solid.Add ""Base:fl"", ""Base:tpT""" & vbCrLf
    AddToHistory "boolean add shapes: Base:fl, Base:tpT", s

    ' 29 - define cylinder: Base:tpB
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""tpB""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dtap/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+ltap""" & vbCrLf
    s = s & "     .Ycenter ""0""" & vbCrLf
    s = s & "     .Zcenter ""-BCfl/2""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:tpB", s

    ' 30 - boolean add shapes: Base:fl, Base:tpB
    s = ""
    s = s & "Solid.Add ""Base:fl"", ""Base:tpB""" & vbCrLf
    AddToHistory "boolean add shapes: Base:fl, Base:tpB", s

    ' 31 - define cylinder: Base:al1
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""al1""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dpst/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+lal""" & vbCrLf
    s = s & "     .Ycenter ""chir*r45""" & vbCrLf
    s = s & "     .Zcenter ""r45""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:al1", s

    ' 32 - boolean add shapes: Base:fl, Base:al1
    s = ""
    s = s & "Solid.Add ""Base:fl"", ""Base:al1""" & vbCrLf
    AddToHistory "boolean add shapes: Base:fl, Base:al1", s

    ' 33 - define cylinder: Base:al2
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""al2""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dpst/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+lal""" & vbCrLf
    s = s & "     .Ycenter ""-chir*r45""" & vbCrLf
    s = s & "     .Zcenter ""-r45""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:al2", s

    ' 34 - boolean add shapes: Base:fl, Base:al2
    s = ""
    s = s & "Solid.Add ""Base:fl"", ""Base:al2""" & vbCrLf
    AddToHistory "boolean add shapes: Base:fl, Base:al2", s

    ' 35 - define cylinder: Base:al3
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""al3""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dprc/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+lal""" & vbCrLf
    s = s & "     .Ycenter ""-chir*r45""" & vbCrLf
    s = s & "     .Zcenter ""r45""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:al3", s

    ' 36 - boolean add shapes: Base:fl, Base:al3
    s = ""
    s = s & "Solid.Add ""Base:fl"", ""Base:al3""" & vbCrLf
    AddToHistory "boolean add shapes: Base:fl, Base:al3", s

    ' 37 - define cylinder: Base:al4
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""al4""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dprc/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""x""" & vbCrLf
    s = s & "     .Xrange ""(-Lwg/2+tboss)-0.1"", ""(-Lwg/2+tboss)+lal""" & vbCrLf
    s = s & "     .Ycenter ""chir*r45""" & vbCrLf
    s = s & "     .Zcenter ""-r45""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:al4", s

    ' 38 - boolean add shapes: Base:fl, Base:al4
    s = ""
    s = s & "Solid.Add ""Base:fl"", ""Base:al4""" & vbCrLf
    AddToHistory "boolean add shapes: Base:fl, Base:al4", s

    ' 39 - transform: rotate Base:fl
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Base:fl""" & vbCrLf
    s = s & "     .Origin ""Free""" & vbCrLf
    s = s & "     .Center ""0"", ""0"", ""0""" & vbCrLf
    s = s & "     .Angle ""0"", ""0"", ""180""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""1""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Rotate""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: rotate Base:fl", s

    ' 40 - boolean subtract shapes: Base:mono, Base:fl
    s = ""
    s = s & "Solid.Subtract ""Base:mono"", ""Base:fl""" & vbCrLf
    AddToHistory "boolean subtract shapes: Base:mono, Base:fl", s

    ' 41 - define cylinder: Base:m3
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""m3""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dm3/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""z""" & vbCrLf
    s = s & "     .Zrange ""(zpart-Hhalf)-0.1"", ""(zpart+Hhalf)+0.1""" & vbCrLf
    s = s & "     .Xcenter ""-2*xm3""" & vbCrLf
    s = s & "     .Ycenter ""ym3""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:m3", s

    ' 42 - transform: mirror Base:m3
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Base:m3""" & vbCrLf
    s = s & "     .Origin ""Free""" & vbCrLf
    s = s & "     .Center ""0"", ""0"", ""0""" & vbCrLf
    s = s & "     .PlaneNormal ""0"", ""1"", ""0""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""1""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Mirror""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: mirror Base:m3", s

    ' 43 - transform: translate Base:m3
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Base:m3""" & vbCrLf
    s = s & "     .Vector ""xm3"", ""0"", ""0""" & vbCrLf
    s = s & "     .UsePickedPoints ""False""" & vbCrLf
    s = s & "     .InvertPickedPoints ""False""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""4""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Translate""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: translate Base:m3", s

    ' 44 - boolean subtract shapes: Base:mono, Base:m3
    s = ""
    s = s & "Solid.Subtract ""Base:mono"", ""Base:m3""" & vbCrLf
    AddToHistory "boolean subtract shapes: Base:mono, Base:m3", s

    ' 45 - transform: translate Base:mono
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Base:mono""" & vbCrLf
    s = s & "     .Vector ""0"", ""0"", ""0""" & vbCrLf
    s = s & "     .UsePickedPoints ""False""" & vbCrLf
    s = s & "     .InvertPickedPoints ""False""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""False""" & vbCrLf
    s = s & "     .Repetitions ""1""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination ""Tapa""" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""False""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Translate""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: translate Base:mono", s

    ' 46 - define brick: Base:cutB
    s = ""
    s = s & "With Brick" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""cutB""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .Xrange ""-Lwg/2-1"", ""Lwg/2+1""" & vbCrLf
    s = s & "     .Yrange ""-Wbody/2-1"", ""Wbody/2+1""" & vbCrLf
    s = s & "     .Zrange ""-Rdisc-1"", ""zpart""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define brick: Base:cutB", s

    ' 47 - define brick: Tapa:cutT
    s = ""
    s = s & "With Brick" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""cutT""" & vbCrLf
    s = s & "     .Component ""Tapa""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .Xrange ""-Lwg/2-1"", ""Lwg/2+1""" & vbCrLf
    s = s & "     .Yrange ""-Wbody/2-1"", ""Wbody/2+1""" & vbCrLf
    s = s & "     .Zrange ""zpart"", ""Rdisc+1""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define brick: Tapa:cutT", s

    ' 48 - boolean intersect shapes: Base:mono, Base:cutB
    s = ""
    s = s & "With Solid" & vbCrLf
    s = s & "     .Version 10" & vbCrLf
    s = s & "     .Intersect ""Base:mono"", ""Base:cutB""" & vbCrLf
    s = s & "     .Version 1" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "boolean intersect shapes: Base:mono, Base:cutB", s

    ' 49 - boolean intersect shapes: Tapa:mono, Tapa:cutT
    s = ""
    s = s & "With Solid" & vbCrLf
    s = s & "     .Version 10" & vbCrLf
    s = s & "     .Intersect ""Tapa:mono"", ""Tapa:cutT""" & vbCrLf
    s = s & "     .Version 1" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "boolean intersect shapes: Tapa:mono, Tapa:cutT", s

    ' 50 - rename block: Base:mono to: Base:base
    s = ""
    s = s & "Solid.Rename ""Base:mono"", ""base""" & vbCrLf
    AddToHistory "rename block: Base:mono to: Base:base", s

    ' 51 - rename block: Tapa:mono to: Tapa:tapa
    s = ""
    s = s & "Solid.Rename ""Tapa:mono"", ""tapa""" & vbCrLf
    AddToHistory "rename block: Tapa:mono to: Tapa:tapa", s

    ' 52 - define cylinder: Base:pA
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""pA""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dpress/2""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""z""" & vbCrLf
    s = s & "     .Zrange ""zpart-lab"", ""zpart+0.1""" & vbCrLf
    s = s & "     .Xcenter ""-xab""" & vbCrLf
    s = s & "     .Ycenter ""yab""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:pA", s

    ' 53 - define cylinder: Base:pB
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""pB""" & vbCrLf
    s = s & "     .Component ""Base""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dpress/2""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""z""" & vbCrLf
    s = s & "     .Zrange ""zpart-lab"", ""zpart+0.1""" & vbCrLf
    s = s & "     .Xcenter ""xab""" & vbCrLf
    s = s & "     .Ycenter ""-yab""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Base:pB", s

    ' 54 - boolean add shapes: Base:pA, Base:pB
    s = ""
    s = s & "Solid.Add ""Base:pA"", ""Base:pB""" & vbCrLf
    AddToHistory "boolean add shapes: Base:pA, Base:pB", s

    ' 55 - boolean subtract shapes: Base:base, Base:pA
    s = ""
    s = s & "Solid.Subtract ""Base:base"", ""Base:pA""" & vbCrLf
    AddToHistory "boolean subtract shapes: Base:base, Base:pA", s

    ' 56 - define cylinder: Tapa:hA
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""hA""" & vbCrLf
    s = s & "     .Component ""Tapa""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dslip/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""z""" & vbCrLf
    s = s & "     .Zrange ""zpart-0.1"", ""(zpart+Hhalf)+0.1""" & vbCrLf
    s = s & "     .Xcenter ""-xab""" & vbCrLf
    s = s & "     .Ycenter ""yab""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Tapa:hA", s

    ' 57 - define cylinder: Tapa:hB
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""hB""" & vbCrLf
    s = s & "     .Component ""Tapa""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""dslip/2+tpl""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""z""" & vbCrLf
    s = s & "     .Zrange ""zpart-0.1"", ""(zpart+Hhalf)+0.1""" & vbCrLf
    s = s & "     .Xcenter ""xab-(-0.911179)*slotL/2""" & vbCrLf
    s = s & "     .Ycenter ""-yab-(0.412011)*slotL/2""" & vbCrLf
    s = s & "     .Segments ""0""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Tapa:hB", s

    ' 58 - transform: translate Tapa:hB
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Tapa:hB""" & vbCrLf
    s = s & "     .Vector ""(-0.911179)*slotL/2"", ""(0.412011)*slotL/2"", ""0""" & vbCrLf
    s = s & "     .UsePickedPoints ""False""" & vbCrLf
    s = s & "     .InvertPickedPoints ""False""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""2""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Translate""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: translate Tapa:hB", s

    ' 59 - boolean add shapes: Tapa:hA, Tapa:hB
    s = ""
    s = s & "Solid.Add ""Tapa:hA"", ""Tapa:hB""" & vbCrLf
    AddToHistory "boolean add shapes: Tapa:hA, Tapa:hB", s

    ' 60 - boolean subtract shapes: Tapa:tapa, Tapa:hA
    s = ""
    s = s & "Solid.Subtract ""Tapa:tapa"", ""Tapa:hA""" & vbCrLf
    AddToHistory "boolean subtract shapes: Tapa:tapa, Tapa:hA", s

    ' 61 - define cylinder: Tapa:hex
    s = ""
    s = s & "With Cylinder" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""hex""" & vbCrLf
    s = s & "     .Component ""Tapa""" & vbCrLf
    s = s & "     .Material ""Ni_plated""" & vbCrLf
    s = s & "     .OuterRadius ""(hexS/2+tpl)/0.8660254""" & vbCrLf
    s = s & "     .InnerRadius ""0.0""" & vbCrLf
    s = s & "     .Axis ""z""" & vbCrLf
    s = s & "     .Zrange ""(zpart+Hhalf)-hexH"", ""(zpart+Hhalf)+0.1""" & vbCrLf
    s = s & "     .Xcenter ""-2*xm3""" & vbCrLf
    s = s & "     .Ycenter ""ym3""" & vbCrLf
    s = s & "     .Segments ""6""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define cylinder: Tapa:hex", s

    ' 62 - transform: mirror Tapa:hex
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Tapa:hex""" & vbCrLf
    s = s & "     .Origin ""Free""" & vbCrLf
    s = s & "     .Center ""0"", ""0"", ""0""" & vbCrLf
    s = s & "     .PlaneNormal ""0"", ""1"", ""0""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""1""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Mirror""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: mirror Tapa:hex", s

    ' 63 - transform: translate Tapa:hex
    s = ""
    s = s & "With Transform" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .Name ""Tapa:hex""" & vbCrLf
    s = s & "     .Vector ""xm3"", ""0"", ""0""" & vbCrLf
    s = s & "     .UsePickedPoints ""False""" & vbCrLf
    s = s & "     .InvertPickedPoints ""False""" & vbCrLf
    s = s & "     .MultipleObjects ""True""" & vbCrLf
    s = s & "     .GroupObjects ""True""" & vbCrLf
    s = s & "     .Repetitions ""4""" & vbCrLf
    s = s & "     .MultipleSelection ""False""" & vbCrLf
    s = s & "     .Destination """"" & vbCrLf
    s = s & "     .Material """"" & vbCrLf
    s = s & "     .AutoDestination ""True""" & vbCrLf
    s = s & "     .Transform ""Shape"", ""Translate""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "transform: translate Tapa:hex", s

    ' 64 - boolean subtract shapes: Tapa:tapa, Tapa:hex
    s = ""
    s = s & "Solid.Subtract ""Tapa:tapa"", ""Tapa:hex""" & vbCrLf
    AddToHistory "boolean subtract shapes: Tapa:tapa, Tapa:hex", s

    ' 65 - define port: 1
    s = ""
    s = s & "With Port" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .PortNumber ""1""" & vbCrLf
    s = s & "     .Label """"" & vbCrLf
    s = s & "     .Folder """"" & vbCrLf
    s = s & "     .NumberOfModes ""1""" & vbCrLf
    s = s & "     .AdjustPolarization ""False""" & vbCrLf
    s = s & "     .PolarizationAngle ""0.0""" & vbCrLf
    s = s & "     .ReferencePlaneDistance ""0""" & vbCrLf
    s = s & "     .TextSize ""50""" & vbCrLf
    s = s & "     .TextMaxLimit ""0""" & vbCrLf
    s = s & "     .Coordinates ""Free""" & vbCrLf
    s = s & "     .Orientation ""xmin""" & vbCrLf
    s = s & "     .PortOnBound ""False""" & vbCrLf
    s = s & "     .ClipPickedPortToBound ""False""" & vbCrLf
    s = s & "     .Xrange ""-Lwg/2"", ""-Lwg/2""" & vbCrLf
    s = s & "     .Yrange ""-aWR/2-tpl"", ""aWR/2+tpl""" & vbCrLf
    s = s & "     .Zrange ""-bWR/2"", ""bWR/2""" & vbCrLf
    s = s & "     .XrangeAdd ""0.0"", ""0.0""" & vbCrLf
    s = s & "     .YrangeAdd ""0.0"", ""0.0""" & vbCrLf
    s = s & "     .ZrangeAdd ""0.0"", ""0.0""" & vbCrLf
    s = s & "     .SingleEnded ""False""" & vbCrLf
    s = s & "     .WaveguideMonitor ""False""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define port: 1", s

    ' 66 - define port: 2
    s = ""
    s = s & "With Port" & vbCrLf
    s = s & "     .Reset" & vbCrLf
    s = s & "     .PortNumber ""2""" & vbCrLf
    s = s & "     .Label """"" & vbCrLf
    s = s & "     .Folder """"" & vbCrLf
    s = s & "     .NumberOfModes ""1""" & vbCrLf
    s = s & "     .AdjustPolarization ""False""" & vbCrLf
    s = s & "     .PolarizationAngle ""0.0""" & vbCrLf
    s = s & "     .ReferencePlaneDistance ""0""" & vbCrLf
    s = s & "     .TextSize ""50""" & vbCrLf
    s = s & "     .TextMaxLimit ""0""" & vbCrLf
    s = s & "     .Coordinates ""Free""" & vbCrLf
    s = s & "     .Orientation ""xmax""" & vbCrLf
    s = s & "     .PortOnBound ""False""" & vbCrLf
    s = s & "     .ClipPickedPortToBound ""False""" & vbCrLf
    s = s & "     .Xrange ""Lwg/2"", ""Lwg/2""" & vbCrLf
    s = s & "     .Yrange ""-aWR/2-tpl"", ""aWR/2+tpl""" & vbCrLf
    s = s & "     .Zrange ""-bWR/2"", ""bWR/2""" & vbCrLf
    s = s & "     .XrangeAdd ""0.0"", ""0.0""" & vbCrLf
    s = s & "     .YrangeAdd ""0.0"", ""0.0""" & vbCrLf
    s = s & "     .ZrangeAdd ""0.0"", ""0.0""" & vbCrLf
    s = s & "     .SingleEnded ""False""" & vbCrLf
    s = s & "     .WaveguideMonitor ""False""" & vbCrLf
    s = s & "     .Create" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define port: 2", s

    ' 67 - define time domain solver parameters
    s = ""
    s = s & "Mesh.SetCreator ""High Frequency""" & vbCrLf
    s = s & "With Solver" & vbCrLf
    s = s & "     .Method ""Hexahedral""" & vbCrLf
    s = s & "     .CalculationType ""TD-S""" & vbCrLf
    s = s & "     .StimulationPort ""All""" & vbCrLf
    s = s & "     .StimulationMode ""All""" & vbCrLf
    s = s & "     .SteadyStateLimit ""-40""" & vbCrLf
    s = s & "     .MeshAdaption ""False""" & vbCrLf
    s = s & "     .AutoNormImpedance ""False""" & vbCrLf
    s = s & "     .NormingImpedance ""50""" & vbCrLf
    s = s & "     .CalculateModesOnly ""False""" & vbCrLf
    s = s & "     .SParaSymmetry ""False""" & vbCrLf
    s = s & "     .StoreTDResultsInCache  ""False""" & vbCrLf
    s = s & "     .RunDiscretizerOnly ""False""" & vbCrLf
    s = s & "     .FullDeembedding ""False""" & vbCrLf
    s = s & "     .SuperimposePLWExcitation ""False""" & vbCrLf
    s = s & "     .UseSensitivityAnalysis ""False""" & vbCrLf
    s = s & "End With" & vbCrLf
    AddToHistory "define time domain solver parameters", s

    MsgBox "UPM v2: 67 pasos añadidos al historial.", vbInformation
End Sub
