--!strict
export type FaceInfo = {
    Id: number,
    Bundle: {
        Id: number,
        Items: {
            DynamicHeadId: number,
            MoodAnimationId: number,
            UserOutfitId: number
        }   
    },
    AssetId: string,
}

export type HeadInfo = {
    Id: number,
    Classic: {
        MeshType: Enum.MeshType?,
        MeshId: string,
        TextureId: string,
        Scale: Vector3?,
        AvatarPartScaleType: string?,
        Attachments: {[string]: CFrame}?,
    },
    Mesh: {
        MeshId: string,
        TextureId: string,
        Size: Vector3?,
        Attachments: {[string]: CFrame}?,
    },
    Shape: string
}

return nil