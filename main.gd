extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var vertices = []
	var indices = []
	var normals = []
	var tangents = []
	var shadows = []
	
	var preloaded_mesh = preload("res://levels/first/collision.obj")
	var level_instance = MeshInstance3D.new()
	level_instance.mesh = preloaded_mesh
	
	level_instance.create_trimesh_collision()
	var loaded_verts = level_instance.get_faces()
	
	#negative is empty
	indices.resize(len(loaded_verts))
	indices.fill(-1)
	
	#remove duplicate vertices
	var i = 0;
	for v0 in loaded_verts:
		if indices[i] == -1:
			indices[i] = i
			vertices.append(v0)
			for j in range(i+1, len(loaded_verts)):
				if v0 == loaded_verts[j]:
					indices[j] = i
		i += 1
	loaded_verts.clear()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
