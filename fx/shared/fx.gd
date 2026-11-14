extends Node3D
## CC0 Hit & Impact sampler player, adapted for BlockNova's silent visual layer.
@export var play_on_ready := true
@export var auto_free := true
var _stopped := false

func _ready() -> void:
    if play_on_ready:
        play()

func play() -> void:
    var longest := 0.0
    var loops := false
    for child in get_children():
        if child is GPUParticles3D or child is CPUParticles3D:
            child.restart()
            longest = maxf(longest, child.lifetime)
            loops = loops or not child.one_shot
    if auto_free and not loops:
        get_tree().create_timer(longest + 0.12).timeout.connect(queue_free)

func stop() -> void:
    if _stopped:
        return
    _stopped = true
    var longest := 0.0
    for child in get_children():
        if child is GPUParticles3D or child is CPUParticles3D:
            child.emitting = false
            longest = maxf(longest, child.lifetime)
    if auto_free:
        get_tree().create_timer(longest + 0.12).timeout.connect(queue_free)
