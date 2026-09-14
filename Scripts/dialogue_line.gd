class_name DialogueLine
extends Resource

@export_multiline var text: String = ""
@export var image: Texture2D = null       # leave empty to keep whatever's currently showing
@export var show_cutscene: bool = false   # whether the cutscene image node should be visible for this line
@export var display_lifetime: float = 0
