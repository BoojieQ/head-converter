# Head Converter
This is a simple library for converting heads / faces between their classic & dynamic variants
- Works on both R6 and R15
- Supports both MeshPart and Part w/ Mesh heads on R15
- Supports head shapes
- Uses scraped data of items / bundles and their ids, may have some errors that require manual correction

# Use
- `HeadConverter.ConvertDescription(description: HumanoidDescription, options: ConvertOptions)`
- `HeadConverter.ConvertHumanoid(humanoid: Humanoid, options: ConvertOptions)`

`ConvertOptions` is a dictionary that takes the following:
- `["HeadType"]: ("Dynamic" | "Classic")` - what type of head to convert to
- `["MeshType"]: ("MeshPart" | "Mesh")?`- what mesh type to use for R15 characters, defaults to either being based on the character's already existing head if called from ConvertHumanoid, or `Workspace.MeshPartHeadsAndAccessories`
- `["RigType"]: Enum.HumanoidRigType?` - specifying the rig type lets the converter know how to handle certain cases, defaults to either the humanoid's rig type if called from ConvertHumanoid, or an R15 rig type