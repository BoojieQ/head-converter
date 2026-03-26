--!strict
local Types = require(script.Parent.Types)

local Faces = require(script.Faces) :: {[string]: Types.FaceInfo}
local Heads = require(script.Heads) :: {[string]: Types.HeadInfo}
local HeadShapes = require(script.HeadShapes) :: {[string]: number}

local CLASSIC_HEAD_ATTACHMENTS = {
    FaceCenterAttachment = CFrame.new(0,0,0);
    FaceFrontAttachment = CFrame.new(0,0,-0.6);
    HairAttachment = CFrame.new(0,0.6,0);
    HatAttachment = CFrame.new(0,0.6,0);
    NeckRigAttachment = CFrame.new(0,-0.5,0);
};

local content = {
    Faces = {
        [0] = {
            Id = 0;
            Bundle = {
                Id = 0;
            };
            AssetId = "rbxasset://textures/face.png";
        };
    } :: {[number]: Types.FaceInfo};
    Heads = {
        [0] = {
            Id = 0;
            Classic = {
                MeshType = Enum.MeshType.Head;
                MeshId = "";
                TextureId = "";
                Scale = Vector3.new(1.25,1.25,1.25);
                Attachments = CLASSIC_HEAD_ATTACHMENTS;
            };
            Mesh = {
                MeshId = "rbxassetid://7430070993";
                TextureId = "";
                Size = Vector3.new(1.198, 1.202, 1.198);
                Attachments = CLASSIC_HEAD_ATTACHMENTS;
            };
        };
    } :: {[number]: Types.HeadInfo};
    Bundles = {} :: {[number]: Types.FaceInfo};
    DynamicHeads = {} :: {[number]: Types.FaceInfo};
    HeadShapes = {} :: {[string]: Types.HeadInfo};
}

for _, faceInfo in Faces do
    content.Faces[faceInfo.Id] = faceInfo
    if faceInfo.Bundle then
        content.Bundles[faceInfo.Bundle.Id] = faceInfo
        local dynamicHeadId = faceInfo.Bundle.Items.DynamicHeadId
        if dynamicHeadId then
            content.DynamicHeads[dynamicHeadId] = faceInfo
        end
    end
end

for _, headInfo in Heads do
    content.Heads[headInfo.Id] = headInfo
end

for shape, headId in HeadShapes do
    local headInfo = content.Heads[headId]
    if headInfo then
        headInfo.Shape = shape;
        content.HeadShapes[shape] = headInfo
    end
end

return content