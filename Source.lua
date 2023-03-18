--Dendro ESP
--Nahida#5000
--Ver 1.1

--#region Setup
--//Services\\--
local RunService = game:GetService("RunService");
local Workspace = game:GetService("Workspace");
local CoreGui = game:GetService("CoreGui");
--//Main Proxy\\--
local DendroESP = newproxy(true);
local DendroMeta = getmetatable(DendroESP);
--//Metamethods\\--
function DendroMeta:__index(Key)
    assert(type(Key) == "string", "Invalid key type.");
    assert(Key:sub(1, 2) ~= "__", "Invalid key.");

    local Meta = getmetatable(self) or self;
    if (Meta[Key] ~= nil) then return Meta[Key]; end;
    error("Invalid key.");
end;

function DendroMeta:__newindex(Key, Value)
    assert(type(Key) == "string", "Invalid key type.");
    assert(Key:sub(1, 2) ~= "__", "Invalid key.");

    local Meta = getmetatable(self) or self;
    assert(Meta[Key] ~= nil, "Invalid key.");
    
    local OldValue = Meta[Key];
    if (type(OldValue) == "function") then error("This key is read-only."); end;
    if (self ~= DendroESP) then
        assert(typeof(Value) == typeof(OldValue), "Invalid value type for "..Key..".");
        Meta[Key] = Value;
        return;
    end;
    Meta[Key] = Value;
    if (not Meta:Render()) then
        Meta[Key] = OldValue;
        error("Invalid value type for "..Key..".");
    end;
end;

function DendroMeta:__tostring()
    return (self == DendroESP and "DendroESP") or "DendroESPRenderingProxy";
end;

function DendroMeta:Render()
    assert(self, "Expected a self call. Please use ':' instead of '.' when calling this function.");
    local Meta = getmetatable(self) or self;

    if (
        typeof(Meta.BulletSource) == "CFrame" or
        (typeof(Meta.BulletSource) == "Instance" and (Meta.BulletSource:IsA("BasePart") or Meta.BulletSource:IsA("Camera")))
    ) then else return; end;
    if (typeof(Meta.BulletOffset) ~= "CFrame") then return; end;

    if (typeof(Meta.WallPenThickness) ~= "number") then return; end;
    if (typeof(Meta.RaycastParams) ~= "RaycastParams") then return; end;

    if (typeof(Meta.PositiveColor) ~= "Color3") then return; end;
    if (typeof(Meta.NegativeColor) ~= "Color3") then return; end;
    if (typeof(Meta.NeutralColor) ~= "Color3") then return; end;
    if (typeof(Meta.RenderState) ~= "boolean") then return; end;

    return true;
end;
--//Defaults\\--
DendroMeta.BulletSource = Workspace.CurrentCamera;
DendroMeta.BulletOffset = CFrame.new();
DendroMeta.WallPenThickness = 0;
DendroMeta.RaycastParams = RaycastParams.new();
--//Inherited Defaults\\--
DendroMeta.PositiveColor = Color3.fromHex("#A5C739");
DendroMeta.NegativeColor = Color3.fromHex("#BE1E2D");
DendroMeta.NeutralColor = Color3.fromHex("#F7941D");
DendroMeta.RenderState = false;
--#endregion

--#region Stack Declaration
--//ENV Stack Declaration\\--
local Min, Max = math.min, math.max;
local Cos, Sin = math.cos, math.sin;
local Rad, PI = math.rad, math.pi;
local Unpack, TRemove = table.unpack, table.remove;

local NewV2 = Vector2.new;
local NewCF = CFrame.new;

local EmptyCF = NewCF();
local Viewport, SetupViewport;
local CanShoot = Instance.new("BindableEvent");
CanShoot.Name = "CanShoot";
DendroMeta.CanShoot = CanShoot;
--//DataModel Stack Declaration\\--
local Camera, Raycast = Workspace.CurrentCamera, Workspace.Raycast;
local ToScreenPoint = Camera.WorldToViewportPoint;
--#endregion

--#region Framework
local DendroProxies = {};
local ESPModes = {
    BoundingBox = {
        SetupMeta = function(Meta)
            Meta.Opacity = 1;
            Meta.Thickness = 1;
        end;
    };
    Vertex = {
        SetupMeta = function(Meta)
            Meta.RenderBoundingBox = false;
            Meta.Opacity = 1;
            Meta.OutlinesOnly = true;
            Meta.Thickness = 1;
        end;
    };
    Shadow = {
        SetupMeta = function(Meta)
            Meta.RenderBoundingBox = false;
            Meta.Opacity = 1;
            Meta.Thickness = 1;
        end;
    };
    Orthogonal = {
        SetupMeta = function(Meta)
            Meta.RenderBoundingBox = false;
            Meta.Opacity = 1;
            Meta.Material = Enum.Material.SmoothPlastic;
        end;
    };
    Highlight = {
        SetupMeta = function(Meta)
            Meta.RenderBoundingBox = false;
            --//Outline\\--
            Meta.OutlineOpacity = 1;
            Meta.PositiveOutlineColor = DendroMeta.PositiveColor;
            Meta.NegativeOutlineColor = DendroMeta.NegativeColor;
            Meta.NeutralOutlineColor = DendroMeta.NeutralColor;
            --//Fill\\--
            Meta.FillOpacity = 0.5;
            Meta.PositiveFillColor = DendroMeta.PositiveColor;
            Meta.NegativeFillColor = DendroMeta.NegativeColor;
            Meta.NeutralFillColor = DendroMeta.NeutralColor;
            --//Removing Inherited Keys\\--
            Meta.PositiveColor = nil;
            Meta.NegativeColor = nil;
            Meta.NeutralColor = nil;
        end;
    };
}
local function CreateRenderingProxy(ESPMode, Part, Type)
    local Proxy = newproxy(true);
    local Meta = getmetatable(Proxy);
    --//Metamethods\\--
    Meta.__index = DendroMeta.__index;
    Meta.__newindex = DendroMeta.__newindex;
    Meta.__tostring = DendroMeta.__tostring;
    Meta.__ESPMode = ESPMode;
    Meta.__Part = Part;
    Meta.__Type = Type;
    --//Inheritance\\--
    Meta.PositiveColor = DendroMeta.PositiveColor;
    Meta.NegativeColor = DendroMeta.NegativeColor;
    Meta.NeutralColor = DendroMeta.NeutralColor;
    Meta.RenderState = DendroMeta.RenderState;
    --//Text\\--
    Meta.TextEnabled = false;
    Meta.Text = "";
    Meta.TextSize = 16;
    Meta.TextAlignment = Enum.TextXAlignment.Left;
    Meta.TextOutlineVisible = false;
    Meta.TextOutlineColor = Color3.new();
    Meta.Font = Drawing.Fonts.Monospace;
    Meta.TextPadding = NewV2(0, 6);
    --//Health\\--
    Meta.HealthEnabled = false;
    Meta.Health = 0;
    Meta.MaxHealth = 100;
    Meta.HealthBarSize = 0;
    Meta.HealthBarThickness = 2;
    Meta.HealthBarPadding = 6;
    --//Crosshair\\--
    Meta.CrosshairEnabled = false;
    Meta.CrosshairOffset = NewCF(0, 2, 0);
    Meta.CrosshairRotationSpeed = 0.5;
    Meta.CrosshairRotation = 45;
    --//Finalization\\--
    Meta.Enabled = true;
    Meta.Render = DendroMeta.__Render;
    Meta.Destroy = DendroMeta.Destroy;
    ESPModes[ESPMode].SetupMeta(Meta);
    DendroProxies[#DendroProxies+1] = Proxy;
    return Proxy;
end;

function DendroMeta:Destroy()
    if (self == DendroESP) then error("Can't destroy the library itself."); end;
    local Meta = getmetatable(self);
    if (typeof(Meta.__Parts) == "Instance") then Meta.__Parts:Destroy(); end;
    if (typeof(Meta.__Highlight) == "Instance") then Meta.__Highlight:Destroy(); end;
    if (type(Meta.__Parts) == "table") then
        for _, __ in pairs(Meta.__Parts) do
            __:Destroy();
        end;
    end;
    Meta.__Parts, Meta.__Highlight = nil, nil;
    for _ = 1, #DendroProxies do
        if (DendroProxies[_] == self) then
            table.remove(DendroProxies, _);
        end;
    end;
end;

function DendroMeta:__Render()
    local Meta = getmetatable(self) or self;
    if (not Meta.Enabled) then return; end;
    if (not Meta.__Part or not Meta.__Part.Parent) then self:Destroy(); end;
    return ESPModes[Meta.__ESPMode].Render(self);
end;

function DendroMeta:AddPart(Part, ESPMode)
    assert(Part:IsA("BasePart"), "Expected BasePart for Arg #1.");
    assert(ESPModes[ESPMode], "Invalid ESPMode.");

    local Proxy = CreateRenderingProxy(ESPMode, Part, "Part");
    if (ESPMode == "Highlight") then
        if (not Viewport) then SetupViewport(); end;
        local Highlight = Instance.new("Highlight", Viewport);
        getmetatable(Proxy).__Highlight = Highlight;
        Highlight.Adornee = Part;
    end;
    if (ESPMode == "Orthogonal") then
        if (not Viewport) then SetupViewport(); end;
        local Replica = Part:Clone();
        Replica:ClearAllChildren();
        Replica.Parent = Viewport;
        getmetatable(Proxy).__Parts = Replica;
    end;
    return Proxy;
end;

function DendroMeta:AddCharacter(Character, ESPMode)
    assert(Character:IsA("Model"), "Expected Character Model for Arg #1.");
    assert(Character:FindFirstChild("HumanoidRootPart"), "Unable to find HumanoidRootPart in this character.");
    assert(ESPModes[ESPMode], "Invalid ESPMode.");

    local Proxy = CreateRenderingProxy(ESPMode, Character, "Character");
    if (ESPMode == "Highlight") then
        if (not Viewport) then SetupViewport(); end;
        local Highlight = Instance.new("Highlight", Viewport);
        getmetatable(Proxy).__Highlight = Highlight;
        Highlight.Adornee = Character;
    end;
    if (ESPMode == "Orthogonal") then
        if (not Viewport) then SetupViewport(); end;
        local Meta = getmetatable(Proxy);
        local Parts = {};
        Meta.__Parts = Parts;
        local Children = Character:GetChildren();
        for _ = 1, #Children do
            local Part = Children[_];
            if (Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart") then
                local Replica = Part:Clone();
                Replica:ClearAllChildren();
                Replica.Parent = Viewport;
                Parts[Part] = Replica;
            end
        end;
    end;
    return Proxy;
end;
--#endregion

--#region Math Hell
local function GetCorners(Part)
    local CF, Size, Corners = Part.CFrame, Part.Size / 2, {};
    for X = -1, 1, 2 do for Y = -1, 1, 2 do for Z = -1, 1, 2 do
        Corners[#Corners+1] = (CF * NewCF(Size * Vector3.new(X, Y, Z))).Position;      
    end; end; end;
    return Corners;
end;

local function GetEdgesNoOverlap(Part)
    local Corners = (type(Part) == "table" and Part) or GetCorners(Part);
    --[[ Corner Data:
        (-1, -1, -1) [1]
        (-1, -1, +1) [2]
        (-1, +1, -1) [3]
        (-1, +1, +1) [4]
        (+1, -1, -1) [5]
        (+1, -1, +1) [6]
        (+1, +1, -1) [7]
        (+1, +1, +1) [8]
    ]]
    -- Binary math haunts me everywhere I go...
    local C000, C001, C010, C011, C100, C101, C110, C111 = Unpack(Corners);
    -- This just takes turns at NOT'ing the bits at [3], [2], and [1] positions, respectively.
    -- First index is b000 << b10 every 3 tables.
    return {
        {C000, C001};
        {C000, C010};
        {C000, C100};
        {C011, C010};
        {C011, C001};
        {C011, C111};
        {C110, C111};
        {C110, C100};
        {C110, C010};
        {C101, C100};
        {C101, C111};
        {C101, C001};
    };
end;

local function GetCharacterVertices(Part)
    if (Part:IsA("Model")) then Part = Part.HumanoidRootPart; end;
    local CF = Part.CFrame;
    return  {
        -- Head
        {CF * NewCF(-0.5, 1, 0).Position, CF * NewCF(-0.5, 2, 0).Position};
        {CF * NewCF(-0.5, 2, 0).Position, CF * NewCF(0.5, 2, 0).Position};
        {CF * NewCF(0.5, 2, 0).Position,  CF * NewCF(0.5, 1, 0).Position};
        -- Right Arm
        {CF * NewCF(0.5, 1, 0).Position, CF * NewCF(2, 1, 0).Position};
        {CF * NewCF(2, 1, 0).Position,   CF * NewCF(2, -1, 0).Position};
        {CF * NewCF(2, -1, 0).Position,  CF * NewCF(1, -1, 0).Position};
        -- Feet
        {CF * NewCF(1, -1, 0).Position,  CF * NewCF(1, -3, 0).Position};
        {CF * NewCF(1, -3, 0).Position,  CF * NewCF(-1, -3, 0).Position};
        {CF * NewCF(-1, -3, 0).Position, CF * NewCF(-1, -1, 0).Position};
        -- Left Arm
        {CF * NewCF(-1, -1, 0).Position, CF * NewCF(-2, -1, 0).Position};
        {CF * NewCF(-2, -1, 0).Position, CF * NewCF(-2, 1, 0).Position};
        {CF * NewCF(-2, 1, 0).Position,  CF * NewCF(-0.5, 1, 0).Position};
    }
end;

local function GetEdges(Part)
    local Corners = (type(Part) == "table" and Part) or GetCorners(Part);
    local Edges, Corner = {}, Corners[1];
    local C0, C1, C2 = Corners[2], Corners[3], Corners[5];

    Edges[1] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };

    Corner, C0, C1, C2 = Corners[2], Corners[1], Corners[4], Corners[6];
    Edges[2] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };

    Corner, C0, C1, C2 = Corners[3], Corners[1], Corners[4], Corners[7];
    Edges[3] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };

    Corner, C0, C1, C2 = Corners[4], Corners[2], Corners[3], Corners[8];
    Edges[4] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };

    Corner, C0, C1, C2 = Corners[5], Corners[1], Corners[6], Corners[7];
    Edges[5] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };

    Corner, C0, C1, C2 = Corners[6], Corners[2], Corners[5], Corners[8];
    Edges[6] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };

    Corner, C0, C1, C2 = Corners[7], Corners[3], Corners[5], Corners[8];
    Edges[7] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };

    Corner, C0, C1, C2 = Corners[8], Corners[4], Corners[6], Corners[7];
    Edges[8] = {
        {Corner, C0, (Corner - C0).Unit};
        {Corner, C1, (Corner - C1).Unit};
        {Corner, C2, (Corner - C2).Unit};
    };
    return Edges;
end;

local InvalidPass = {[0] = true, [3] = true};
local function CheckShadow(Corner, LightSource)
    local LightDirection = (LightSource - Corner[1][1]).Unit;
    local Passes = 0;
    for _ = 1, 3 do
        local Edge = Corner[_];
        local Dot = Edge[3]:Dot(LightDirection);
        Edge[4] = Dot;
        Passes = Passes + ((Dot >= 0 and 1) or 0);
    end;
    return InvalidPass[Passes];
end;

local function RemoveConnection(Connections, P0, P1)
    for _ = 1, #Connections do
        local Connection = Connections[_];
        if (Connection[1] == P0 and Connection[2] == P1) then
            return TRemove(Connections, _);
        end;
    end;
end;

local function GetShadowPolygon(Part, LightSource)
    local Edges = GetEdges(Part);
    local ShadowCorners, ShadowEdges, Blacklist = {}, {}, {};

    for _ = 1, #Edges do
        local Corner = Edges[_];
        if (not Corner) then break; end;
        if (CheckShadow(Corner, LightSource)) then
            Blacklist[Corner[1][1]] = true;
        else
            ShadowCorners[#ShadowCorners+1] = Corner;
        end;
    end;

    local PointConnections, Tripoint = {}, nil;
    for _ = 1, #ShadowCorners do
        local Corner = ShadowCorners[_];
        local Start = Corner[1][1];
        for _ = 1, 3 do
            local End = Corner[_][2];
            if (not Blacklist[End] and Corner[_][4] ~= 0) then
                ShadowEdges[#ShadowEdges+1] = {Start, End};
                local StartConn, EndConn = (PointConnections[Start] or 0) + 1, (PointConnections[End] or 0) + 1;
                PointConnections[Start] = StartConn;
                PointConnections[End] = EndConn;
                if (StartConn == 3 and EndConn == 3) then
                    ShadowEdges[#ShadowEdges] = nil;
                elseif (StartConn == 3 or EndConn == 3) then
                    local Tricon = (StartConn == 3 and Start) or End;
                    if (Tripoint) then
                        RemoveConnection(ShadowEdges, Tripoint, Tricon);
                    else
                        Tripoint = Tricon;
                    end;
                end;
            end;
        end;
        Blacklist[Start] = true;
    end;

    return ShadowEdges;
end;

-- Converts lines that pass through P0 and P1 into [Ax + By + C = 0] form. This is so that we can easily get the intersection.
local function GetLineComponents(P0, P1)
    local X1, Y1, X2, Y2 = P0.X, P0.Y, P1.X, P1.Y;
    local A = Y1 - Y2;
    local B = X2 - X1;
    local C = X1 * Y2 - X2 * Y1;

    return A, B, C;
end;
-- Gets the intersection of 2 lines to determine where the angle break happens.
local function GetIntersection(L0, L1)
    local A1, B1, C1 = GetLineComponents(L0[1], L0[2]);
    local A2, B2, C2 = GetLineComponents(L1[1], L1[2]);
    local Denominator = (A1*B2-A2*B1);
    local X = (B1*C2-B2*C1)/Denominator;
    local Y = (C1*A2-C2*A1)/Denominator;
    return NewV2(X, Y);
end;

local function GetTPoint(P0, P1, T)
    return P0 * (1 - T) + P1 * T;
end;

local function V3ToV2(Vector, ...)
    return NewV2(Vector.X, Vector.Y), ...;
end;

local function GetPart(Part)
    if (Part:IsA("Part")) then return Part; end;
    if (Part:IsA("Model")) then return Part:FindFirstChild("HumanoidRootPart") or Part.PrimaryPart; end;
    return Part;
end;
--#endregion

--#region Custom Drawing Library Implementation
--Recycles Drawing tables because Synapse sucks at garbage collection.
local Drawings = {};
local function CreateDrawing(Type)
    if (not Drawings[Type]) then Drawings[Type] = {Count = 0}; end;
    local DrawingTable = Drawings[Type];
    local Count = DrawingTable.Count + 1;
    local Component = DrawingTable[Count];
    DrawingTable.Count = Count;
    if (Component) then return Component; end;
    Component = Drawing.new(Type);
    DrawingTable[Count] = Component;
    return Component;
end;
Drawing.new("Line"):Remove();

local function DrawLine(P0, P1, Color, Thickness, Transparency, Is2D)
    if (not Is2D) then
        local Start = ToScreenPoint(Camera, P0);
        local End = ToScreenPoint(Camera, P1);
        P0, P1 = V3ToV2(Start), V3ToV2(End);
    end;

    local Line = CreateDrawing("Line");
    Line.Color = Color;
    Line.From, Line.To = P0, P1;
    Line.Visible = true;
    Line.Thickness = Thickness;
    Line.Transparency = 1 - Transparency;
    return Line;
end;

local function DrawText(Meta)
    local Text = Meta.Text;
    if (not Meta.TextEnabled or Text == "") then return; end;
    local TextAlignment, Font, Size = Meta.TextAlignment, Meta.Font, Meta.TextSize;
    local TextOutlineVisible, TextOutlineColor = Meta.TextOutlineVisible, Meta.TextOutlineColor;
    local TextDrawing = CreateDrawing("Text");
    TextDrawing.Visible = true;
    TextDrawing.Text, TextDrawing.Font, TextDrawing.Size, TextDrawing.Color = Text, Font, Size, Meta.CurrentColor;
    TextDrawing.Outline, TextDrawing.OutlineColor = TextOutlineVisible, TextOutlineColor;
    local TextPadding = Meta.TextPadding;
    if (TextAlignment == Enum.TextXAlignment.Center) then
        TextDrawing.Center = true;
        TextDrawing.Position = NewV2(
            (Meta.MinX + Meta.MaxX) / 2 + TextPadding.X,
            Meta.MaxY + TextPadding.Y
        );
    elseif (TextAlignment == Enum.TextXAlignment.Right) then
        local TextBounds = TextDrawing.TextBounds;
        TextDrawing.Center = true;
        TextDrawing.Position = NewV2(
            Meta.MaxX - TextBounds.X / 2 - TextPadding.X,
            Meta.MaxY + TextPadding.Y
        );
    else
        TextDrawing.Center = false;
        TextDrawing.Position = NewV2(
            Meta.MinX + TextPadding.X,
            Meta.MaxY + TextPadding.Y
        );
    end;
    return TextDrawing;
end;

local function DrawHealth(Meta)
    if (not Meta.HealthEnabled) then return; end;
    local Humanoid = Meta.__Part:FindFirstChildOfClass("Humanoid");
    local Health, MaxHealth = (Humanoid and Humanoid.Health or Meta.Health), (Humanoid and Humanoid.MaxHealth or Meta.MaxHealth);
    if (Health >= MaxHealth or Health <= 0) then return; end;
    local HealthBarSize, HealthBarThickness = Meta.HealthBarSize, Meta.HealthBarThickness;
    local MinX, MaxX, MinY = Meta.MinX, Meta.MaxX, Meta.MinY;
    local Padding = Meta.HealthBarPadding;
    HealthBarSize = ((HealthBarSize == 0 and MaxX - MinX) or HealthBarSize) / 2;

    local HealthBar, MaxHealthBar = CreateDrawing("Line"), CreateDrawing("Line");
    HealthBar.Thickness, MaxHealthBar.Thickness = HealthBarThickness, HealthBarThickness;
    HealthBar.Color = Meta.PositiveColor or Meta.PositiveFillColor;
    MaxHealthBar.Color = Meta.NegativeColor or Meta.NegativeFillColor;
    local Midpoint = (MinX + MaxX) / 2;
    local BarStart, BarEnd, BarY = Midpoint - HealthBarSize, Midpoint + HealthBarSize, MinY - Padding - HealthBarThickness / 2;
    local HealthPoint = NewV2(BarStart + HealthBarSize * 2 * Health / MaxHealth, BarY);
    BarStart, BarEnd = NewV2(BarStart, BarY), NewV2(BarEnd, BarY);
    HealthBar.From = BarStart;
    MaxHealthBar.From = BarEnd;
    HealthBar.To, MaxHealthBar.To = HealthPoint, HealthPoint;
    HealthBar.Visible, MaxHealthBar.Visible = true, true;
end;

local function DrawLineOnRadius(Center, Radian, R0, R1, Color, Thickness)
    local XComponent, YComponent = Cos(Radian), Sin(Radian);
    local Line = CreateDrawing("Line");
    Line.Color, Line.Thickness = Color, Thickness;
    Line.From = Center + NewV2(XComponent * R0, YComponent * R0);
    Line.To = Center + NewV2(XComponent * R1, YComponent * R1);
    Line.Visible = true;
    return Line;
end;

local function DrawCrosshair(Meta, CF)
    if (not Meta.CrosshairEnabled) then return; end;
    CF = CF * Meta.CrosshairOffset;
    CF = V3ToV2(ToScreenPoint(Camera, CF.Position));

    local Color = Meta.CurrentColor;
    local CenterDot = CreateDrawing("Circle");
    CenterDot.Filled = true;
    CenterDot.Thickness = 0;
    CenterDot.Radius = 4;
    CenterDot.Color = Color;
    CenterDot.Position = CF;
    CenterDot.Visible = true;
    local OuterRadius = CreateDrawing("Circle");
    OuterRadius.Radius = 11;
    OuterRadius.Thickness = 3;
    OuterRadius.Color = Color;
    OuterRadius.Position = CF;
    OuterRadius.Visible = true;
    local Rotation = Rad(Meta.CrosshairRotation);
    DrawLineOnRadius(CF, Rotation, 5, 15, Color, 3);
    DrawLineOnRadius(CF, Rotation + PI * 0.5, 5, 15, Color, 3);
    DrawLineOnRadius(CF, Rotation + PI, 5, 15, Color, 3);
    DrawLineOnRadius(CF, Rotation + PI * 1.5, 5, 15, Color, 3);
    Meta.CrosshairRotation = Meta.CrosshairRotation + Meta.CrosshairRotationSpeed;
end;
--#endregion

--#region Projection Functions

local function ToScreenLine(Line)
    local S0, S1;
    Line[1], S0 = V3ToV2(ToScreenPoint(Camera, Line[1]));
    Line[2], S1 = V3ToV2(ToScreenPoint(Camera, Line[2]));
    Line[3] = S0 and S1;
    return Line;
end;
--//Raycast Functions\\--
local function GetBulletSource()
    local BulletSource = (DendroESP.BulletSource or Camera);
    if (typeof(BulletSource) == "Instance") then BulletSource = BulletSource.CFrame; end;
    if (typeof(BulletSource) == "CFrame") then
        BulletSource = (BulletSource * (DendroESP.BulletOffset or EmptyCF)).Position;
    elseif (typeof(BulletSource ~= "Vector3")) then return false;
    end;
    return BulletSource;
end;

local function ProjectPoint(Point, Source)
    local Direction = (Point - Source).Unit * 5000;
    local Raycast = Raycast(Workspace, Source, Direction, DendroESP.RaycastParams);
    return (Raycast and Raycast.Position) or Source + Direction;
end;

local function ProjectLine(Line, Source)
    Line[1] = ProjectPoint(Line[1], Source);
    Line[2] = ProjectPoint(Line[2], Source);
    return Line;
end;

local function GetRenderState(Point, RenderState, Part)
    if (not RenderState) then return "Positive"; end;
    local BulletSource = GetBulletSource();
    local Delta = (Point - BulletSource);
    if (Delta.Magnitude >= 5e3) then return "Negative"; end;
    local RaycastResult = Raycast(Workspace, BulletSource, Delta, DendroESP.RaycastParams);
    if (not RaycastResult or RaycastResult.Instance == Part or RaycastResult.Instance:IsDescendantOf(Part)) then return "Positive"; end;
    local WallPenThickness = DendroESP.WallPenThickness;
    if (not WallPenThickness or WallPenThickness == 0) then return "Negative"; end;
    local NewSource = RaycastResult.Position + Delta.Unit * WallPenThickness;
    if (not Raycast(Workspace, NewSource, Delta.Unit * -WallPenThickness)) then return "Negative"; end;
    RaycastResult = Raycast(Workspace, NewSource, (Point - NewSource), DendroESP.RaycastParams);
    if (not RaycastResult or RaycastResult.Instance == Part or RaycastResult.Instance:IsDescendantOf(Part)) then return "Neutral"; end;
    return "Negative";
end;
--#endregion

--#region Rendering Functions
local ShootIndex = 0;
function ESPModes.BoundingBox:Render(NoDraw)
    local Meta = getmetatable(self) or self;
    local Part, Type = Meta.__Part, Meta.__Type;
    local Hrp = Part;
    if (Type == "Character") then
        Part = Part:FindFirstChild("HumanoidRootPart");
        if (not Part) then return; end;
        Part = {
            CFrame = Part.CFrame - Vector3.new(0, 0.5, 0);
            Position = Part.Position - Vector3.new(0, 0.5, 0);
            Size = Vector3.new(4, 5, 1);
        };
    end;

    local Corners = GetCorners(Part);
    local XPoints, YPoints, OnScreen = {}, {}, false;
    for _ = 1, #Corners do
        local Corner, PointOnScreen = ToScreenPoint(Camera, Corners[_]);
        OnScreen = OnScreen or PointOnScreen;
        XPoints[#XPoints+1] = Corner.X;
        YPoints[#YPoints+1] = Corner.Y;
    end;
    local MinX, MaxX, MinY, MaxY = 
    Min(Unpack(XPoints)),
    Max(Unpack(XPoints)),
    Min(Unpack(YPoints)),
    Max(Unpack(YPoints));

    Meta.MinX, Meta.MaxX, Meta.MinY, Meta.MaxY, Meta.OnScreen = MinX, MaxX, MinY, MaxY, OnScreen;
    local RenderState = GetRenderState(Part.Position, Meta.RenderState, Hrp);
    if (RenderState == "Positive") then
        CanShoot:Fire(Meta.__Part, ShootIndex);
        ShootIndex = ShootIndex + 1;
    end;
    Meta.LastState = RenderState;
    local Color = (Meta[RenderState.."Color"] or Meta[RenderState.."OutlineColor"]);
    Meta.CurrentColor = Color;

    if (not OnScreen) then return; end;
    DrawText(Meta);
    DrawHealth(Meta);
    DrawCrosshair(Meta, Part.CFrame);
    if (NoDraw) then return; end;
    local Thicknes, Transparency = (Meta.Thickness or  1), 1 - (Meta.Opacity or Meta.OutlineOpacity);
    DrawLine(NewV2(MinX, MinY), NewV2(MinX, MaxY), Color, Thicknes, Transparency, true);
    DrawLine(NewV2(MinX, MinY), NewV2(MaxX, MinY), Color, Thicknes, Transparency, true);
    DrawLine(NewV2(MaxX, MaxY), NewV2(MaxX, MinY), Color, Thicknes, Transparency, true);
    DrawLine(NewV2(MaxX, MaxY), NewV2(MinX, MaxY), Color, Thicknes, Transparency, true);
    return true;
end

local function DrawEdges(Edges, Color, Thickness, Transparency)
    for _ = 1, #Edges do
        local Edge = Edges[_];
        DrawLine(Edge[1], Edge[2], Color, Thickness, Transparency);
    end;
end
function ESPModes.Vertex:Render()
    local Meta = getmetatable(self) or self;
    local Part, Type = Meta.__Part, Meta.__Type;
    local EdgeFunction = (Meta.OutlinesOnly and GetShadowPolygon) or GetEdgesNoOverlap;
    ESPModes.BoundingBox.Render(Meta, not Meta.RenderBoundingBox);
    if (not Meta.OnScreen) then return; end;

    local Color, Thickness, Transparency = Meta.CurrentColor, Meta.Thickness, 1 - Meta.Opacity;
    if (Type == "Character") then
        local Parts = Part:GetChildren();
        for _ = 1, #Parts do
            local BasePart = Parts[_];
            if (BasePart:IsA("BasePart")) then
                local Edges = EdgeFunction(BasePart, Camera.CFrame.Position);
                DrawEdges(Edges, Color, Thickness, Transparency);
            end;
        end;
    else
        local Edges = EdgeFunction(Part, Camera.CFrame.Position);
        DrawEdges(Edges, Color, Thickness, Transparency);
    end;
end;

local function RenderShadow(Edges, BulletSource, Color, Thickness, Transparency)
    for _ = 1, #Edges do
        local Edge3D = Edges[_];
        local StartLine, EndLine = {Edge3D[1], GetTPoint(Edge3D[1], Edge3D[2], 0.01)}, {Edge3D[2], GetTPoint(Edge3D[1], Edge3D[2], 0.99)};
        ProjectLine(StartLine, BulletSource); ProjectLine(EndLine, BulletSource);
        ToScreenLine(StartLine); ToScreenLine(EndLine);
        if (StartLine[3] and EndLine[3]) then
            local Midpoint = GetIntersection(StartLine, EndLine);
            local Distance, MaxDistance = 
            math.max((StartLine[1] - Midpoint).Magnitude, (EndLine[1] - Midpoint).Magnitude),
            (StartLine[1] - EndLine[1]).Magnitude;

            if (Distance >= MaxDistance) then
                DrawLine(StartLine[1], EndLine[1], Color, Thickness, Transparency, true);
            else
                DrawLine(StartLine[1], Midpoint, Color, Thickness, Transparency, true);
                DrawLine(Midpoint, EndLine[1], Color, Thickness, Transparency, true);
            end;
        end;
    end;
end;
function ESPModes.Shadow:Render()
    local Meta = getmetatable(self) or self;
    local Part, Type = Meta.__Part, Meta.__Type;
    local BulletSource = GetBulletSource();
    Part = GetPart(Part);
    if (Raycast(Workspace, BulletSource, (Part.CFrame.Position - BulletSource), DendroESP.RaycastParams)) then
        Meta.OutlinesOnly = true;
        ESPModes.Vertex.Render(Meta);
        Meta.OutlinesOnly = nil;
        return false;
    end;
    ESPModes.BoundingBox.Render(Meta, not Meta.RenderBoundingBox);
    if (not Meta.OnScreen) then return; end;

    local Color, Thickness, Transparency = Meta.CurrentColor, Meta.Thickness, 1 - Meta.Opacity;
    if (Type == "Character") then
        local Edges = GetCharacterVertices(Part);
        RenderShadow(Edges, BulletSource, Color, Thickness, Transparency);
    else
        local Edges = GetShadowPolygon(Part, BulletSource);
        RenderShadow(Edges, BulletSource, Color, Thickness, Transparency);
    end;
end;

SetupViewport = function()
    Viewport = Instance.new("ViewportFrame", Instance.new("ScreenGui", CoreGui));
    Viewport.Parent.Name = "DendroESP";
    Viewport.Parent.IgnoreGuiInset = true;
    Viewport.Name = "DendroOrthogonalESP";
    Viewport.Size = UDim2.new(1, 0, 1, 0);
    Viewport.Position = UDim2.new(0.5, 0, 0.5, 0);
    Viewport.AnchorPoint = Vector2.new(0.5, 0.5);
    Viewport.BackgroundTransparency = 1;
end;
function ESPModes.Orthogonal:Render()
    local Meta = getmetatable(self) or self;
    local Part, Type = Meta.__Part, Meta.__Type;
    ESPModes.BoundingBox.Render(Meta, not Meta.RenderBoundingBox);
    if (not Meta.OnScreen) then return; end;

    if (Type == "Part") then
        local Replica = Meta.__Parts;
        if (not Replica) then return; end;
        Replica.Size, Replica.CFrame = Part.Size, Part.CFrame;
        Replica.Color, Replica.Transparency = Meta.CurrentColor, 1 - Meta.Opacity;
        return;
    end;
    if (not Meta.__Parts) then return; end;
    for Source, Replica in pairs(Meta.__Parts) do
        Replica.Size, Replica.CFrame = Source.Size, Source.CFrame;
        Replica.Color, Replica.Transparency = Meta.CurrentColor, 1 - Meta.Opacity;
    end;
end;

function ESPModes.Highlight:Render()
    local Meta = getmetatable(self) or self;
    ESPModes.BoundingBox.Render(Meta, not Meta.RenderBoundingBox);
    if (not Meta.OnScreen) then return; end;
    local Highlight = Meta.__Highlight;
    if (not Highlight) then return; end;
    Highlight.OutlineTransparency = 1 - Meta.OutlineOpacity;
    Highlight.FillTransparency = 1 - Meta.FillOpacity;
    local State = Meta.LastState;
    Highlight.OutlineColor = Meta[State.."OutlineColor"];
    Highlight.FillColor = Meta[State.."FillColor"];
end;
--#endregion

--#region Rendering
if (_G.DendroESPConnection) then _G.DendroESPConnection:Disconnect(); end;
if (CoreGui:FindFirstChild("DendroESP")) then CoreGui.DendroESP:Destroy(); end;
_G.DendroESPConnection = RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera;
    ShootIndex = 0;
    if (Viewport) then Viewport.CurrentCamera = Camera; end;
    for _ = 1, #DendroProxies do
        local Proxy = DendroProxies[_];
        if (not Proxy) then return; end;
        Proxy:Render();
    end;
    for _, Drawings in pairs(Drawings) do
        for Idx = Drawings.Count + 1, #Drawings do
            Drawings[Idx].Visible = false;
        end;
        Drawings.Count = 0;
    end;
end);
--#endregion

return DendroESP;
