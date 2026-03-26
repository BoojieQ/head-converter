--!strict
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")

local Promise = require(script.Parent.Promise)
local Content = require(script.Content)
local Types = require(script.Types)

type HeadInfo = Types.HeadInfo
type FaceInfo = Types.FaceInfo

type HeadType = "Dynamic" | "Classic"
type HeadMeshType = "MeshPart" | "Mesh"
 
type HeadInstanceInfo = {
    Mesh: SpecialMesh,
    MeshPart: MeshPart,
}

local headInstances = {} :: {[number]: HeadInstanceInfo}
local meshPartPromises = {} :: {[HeadInstanceInfo]: Promise.Class}

-- there's probably a better way to do this
local promiseDefaultMeshType: Promise.Class
do
    local description: HumanoidDescription, character: Model
    promiseDefaultMeshType = Promise.new(function(resolve)
        description = Instance.new("HumanoidDescription")
        character = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
        local head = character:WaitForChild("Head")
        if head:IsA("MeshPart") then
            resolve("MeshPart")
        else
            resolve("Mesh")
        end
    end):finally(function()
        if description then
            description:Destroy()
        end
        if character then
            character:Destroy()
        end
    end)
end

local function getHeadBodyPartDescription(description: HumanoidDescription): BodyPartDescription?
    for _, v in description:GetChildren() do
        if v:IsA("BodyPartDescription") and v.BodyPart == Enum.BodyPart.Head then
            return v
        end
    end
    return nil
end

local function buildMeshPartHead(head: BasePart, attachments: {[string]: CFrame}?)
    if not head:FindFirstChild("OriginalSize") then
        local originalSize = Instance.new("Vector3Value")
        originalSize.Name = "OriginalSize"
        originalSize.Value = head.Size
        originalSize.Parent = head
    end

    if not head:FindFirstChild("face") then
        local faceDecal = Instance.new("Decal")
        faceDecal.Name = "face"
        faceDecal.Parent = head
    end

    if attachments then
        for name, origin in attachments do
            if head:FindFirstChild(name) then
                continue
            end
    
            local attachment = Instance.new("Attachment")
            attachment.Name = name
            attachment.CFrame = origin
    
            local originalPosition = Instance.new("Vector3Value")
            originalPosition.Name = "OriginalPosition"
            originalPosition.Value = attachment.Position
            originalPosition.Parent = attachment
    
            attachment.Parent = head
        end
    end
end

local function buildMeshHead(mesh: SpecialMesh, attachments: {[string]: CFrame}?)
    if not mesh:FindFirstChild("OriginalSize") then
        local originalSize = Instance.new("Vector3Value")
        originalSize.Name = "OriginalSize"
        originalSize.Value = Vector3.new(2,1,1)
        originalSize.Archivable = false
        originalSize.Parent = mesh
    end
    
    if attachments then
        for name, origin in attachments do
            if mesh:FindFirstChild(name) then
                continue
            end
    
            local attachment = Instance.new("Attachment")
            attachment.Name = name
            attachment.CFrame = origin
            attachment.Archivable = false
    
            local originalPosition = Instance.new("Vector3Value")
            originalPosition.Name = "OriginalPosition"
            originalPosition.Value = attachment.Position
            originalPosition.Parent = attachment
    
            attachment.Parent = mesh
        end
    end
    mesh:Clone().Parent = workspace
end

-- in practice this is only used for the default head on R15 at the moment
-- could be simplified down to handling just that specific case instead of being generic
local function getHeadInstance(id: number, meshType: HeadMeshType): (MeshPart | SpecialMesh)?
    assert(meshType == "MeshPart" or meshType == "Mesh", "invalid mesh type")
    local headInfo = Content.Heads[id]
    local headInstanceInfo = headInstances[id]
    if headInstanceInfo == nil then
        headInstanceInfo = {} :: HeadInstanceInfo
        headInstances[id] = headInstanceInfo
    end
    if meshType == "MeshPart" then
        if headInstanceInfo.MeshPart then
            return headInstanceInfo.MeshPart
        else
            local promise = meshPartPromises[headInstanceInfo]
            if not promise then
                promise = Promise.new(function(resolve)
                    local meshPart = InsertService:CreateMeshPartAsync(headInfo.Mesh.MeshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Precise)
                    meshPart.Name = "Head"
                    meshPart.TextureID = headInfo.Mesh.TextureId
                    if headInfo.Mesh.Size then
                        meshPart.Size = headInfo.Mesh.Size
                    end
                    
                    buildMeshPartHead(meshPart, headInfo.Mesh.Attachments)
                    meshPart:SetAttribute("Classic", true)
                    headInstanceInfo.MeshPart = meshPart

                    resolve(meshPart)
                end):finally(function()
                    meshPartPromises[headInstanceInfo] = nil
                end)
                meshPartPromises[headInstanceInfo] = promise
            end
            return promise:expect() :: MeshPart
        end
    elseif meshType == "Mesh" then
        if headInstanceInfo.Mesh then
            return headInstanceInfo.Mesh
        else
            local mesh = Instance.new("SpecialMesh")
            mesh.Name = "Mesh"
            mesh.MeshType = headInfo.Classic.MeshType or Enum.MeshType.FileMesh
            if headInfo.Classic.Scale then
                mesh.Scale = headInfo.Classic.Scale
            end
            if mesh.MeshType == Enum.MeshType.FileMesh then
                mesh.MeshId = headInfo.Classic.MeshId
                mesh.TextureId = headInfo.Classic.TextureId
            end

            local avatarPartScaleType = Instance.new("StringValue")
            avatarPartScaleType.Name = "AvatarPartScaleType"
            avatarPartScaleType.Value = headInfo.Classic.AvatarPartScaleType or "Classic"
            avatarPartScaleType.Archivable = false
            avatarPartScaleType.Parent = mesh

            buildMeshHead(mesh, headInfo.Classic.Attachments)
            mesh:SetAttribute("Classic", true)
            headInstanceInfo.Mesh = mesh
            
            return mesh
        end
    end
    return nil
end

type InfoResult = {
    HeadType: HeadType | "",
    Head: HeadInfo,
    Face: FaceInfo
}

local function getInfo(description: HumanoidDescription): InfoResult
    local headType: HeadType | "" = ""
    local headInfo: HeadInfo, faceInfo: FaceInfo
    local isDynamic = false

    if description.Head ~= 0 then
        isDynamic = Content.DynamicHeads[description.Head] ~= nil
    else
        local headDescription = getHeadBodyPartDescription(description)
        if headDescription and headDescription.HeadShape ~= "" then
            isDynamic = true
        end
    end

    if isDynamic then
        local headDescription = getHeadBodyPartDescription(description)
        local shape = (headDescription and headDescription.HeadShape) or ""
        headType = "Dynamic"
        headInfo = Content.HeadShapes[shape] or Content.HeadShapes["RobloxClassic"]
        faceInfo = Content.DynamicHeads[description.Head] or Content.Faces[0]
    else
        headType = "Classic"
        headInfo = Content.Heads[description.Head]
        faceInfo = Content.Faces[description.Face]
    end
    
    return {
        HeadType = headType;
        Head = headInfo;
        Face = faceInfo;
    } :: InfoResult
end

type ConvertOptions = {
    HeadType: HeadType,
    MeshType: HeadMeshType?,
    RigType: Enum.HumanoidRigType?,
}

local function convertDescription(description: HumanoidDescription, options: ConvertOptions): boolean
    local info = getInfo(description)
    local rigType = (options and options.RigType) or Enum.HumanoidRigType.R15
    local headType = (options and options.HeadType) or "Classic"
    local headMeshType: string = (options and options.MeshType) or (rigType == Enum.HumanoidRigType.R15 and promiseDefaultMeshType:expect()) or "Mesh"
    if info.HeadType ~= headType then
        if headType == "Classic" then
            if headMeshType == "MeshPart" then
                local headBodyPartDescription = getHeadBodyPartDescription(description) :: BodyPartDescription
                if info.Head.Id == 0 and rigType == Enum.HumanoidRigType.R15 then
                    local headMeshPartInstance = getHeadInstance(info.Head.Id, "MeshPart")
                    if headMeshPartInstance then
                        if not headBodyPartDescription then
                            headBodyPartDescription = Instance.new("BodyPartDescription")
                            headBodyPartDescription.BodyPart = Enum.BodyPart.Head
                            headBodyPartDescription.Parent = description
                        end
                        headBodyPartDescription.HeadShape = ""
                        headBodyPartDescription.Instance = headMeshPartInstance
                    end
                    description.Head = 0
                else
                    if headBodyPartDescription then
                        headBodyPartDescription.HeadShape = ""
                    end
                    description.Head = info.Head.Id
                end
            elseif headMeshType == "Mesh" then
                local headBodyPartDescription = getHeadBodyPartDescription(description) :: BodyPartDescription
                if info.Head.Id == 0 and rigType == Enum.HumanoidRigType.R15 then
                    local headMeshInstance = getHeadInstance(info.Head.Id, "Mesh")
                    if headMeshInstance then
                        if not headBodyPartDescription then
                            headBodyPartDescription = Instance.new("BodyPartDescription")
                            headBodyPartDescription.BodyPart = Enum.BodyPart.Head
                            headBodyPartDescription.Parent = description
                        end
                        headBodyPartDescription.HeadShape = ""
                        headBodyPartDescription.Instance = headMeshInstance
                    end
                else
                    if headBodyPartDescription then
                        headBodyPartDescription.HeadShape = ""
                    end
                    description.Head = info.Head.Id
                end
            end
            description.Face = info.Face.Id
        elseif headType == "Dynamic" then
            if info.Face.Bundle and info.Face.Bundle.Items.DynamicHeadId then
                local headBodyPartDescription = getHeadBodyPartDescription(description) :: BodyPartDescription
                if not headBodyPartDescription then
                    headBodyPartDescription = Instance.new("BodyPartDescription")
                    headBodyPartDescription.BodyPart = Enum.BodyPart.Head
                    headBodyPartDescription.Parent = description
                end
                if headBodyPartDescription.Instance and headBodyPartDescription.Instance:GetAttribute("Classic") then
                    headBodyPartDescription.Instance = nil :: any
                end
                headBodyPartDescription.HeadShape = info.Head.Shape or ""
                headBodyPartDescription.AssetId = info.Face.Bundle.Items.DynamicHeadId
                description.Face = 0
            end
        end
        return true
    end
    return false
end

local function convertHumanoid(humanoid: Humanoid, options: ConvertOptions): boolean
    local description = humanoid:GetAppliedDescription()
    if description then
        local parameters = {
            HeadType = options.HeadType;
            MeshType = options.MeshType;
            RigType = options.RigType or humanoid.RigType;
        } :: ConvertOptions
        if parameters.MeshType == nil then
            local head = (humanoid.Parent and humanoid.Parent:FindFirstChild("Head")) or nil :: BasePart?
            if head then
                parameters.MeshType = if head:IsA("MeshPart") then "MeshPart" else "Mesh"
            end
        end
        local converted = convertDescription(description, parameters)
        if converted then
            humanoid:ApplyDescriptionAsync(description)
            return true
        end
    end
    return false
end

return {
    ConvertDescription = convertDescription;
    ConvertHumanoid = convertHumanoid;
}