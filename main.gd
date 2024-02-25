extends Node3D

func sort_edge(a,b):
	if a>b:
		return b+","+a
	return a+","+b

func triangle_area(v0, v1, v2):
	var AB = v1 - v0
	var CA = v0 - v2
	return (CA*(AB.dot(AB)) - AB*(CA.dot(AB))).dot(v1 - v2)
func isRight(v0, v1, v2):
	return triangle_area(v0,v1,v2) < 0
func isLeft(v0, v1, v2):
	return triangle_area(v0,v1,v2) > 0
func isRightOn(v0, v1, v2):
	return triangle_area(v0,v1,v2) <= 0
func isLeftOn(v0, v1, v2):
	return triangle_area(v0,v1,v2) <= 0

func value_at(v, i):
	var s = len(v)
	if i<0:
		return v[i%s + s]
	return v[i%s]

func lineInt(l0,l1):
	var A = l0[1]-l0[0]
	var B = l1[1]-l1[0]
	var C = l1[0]-l0[0]
	var D = C - B*C.dot(B)/B.dot(B)
	return l0[0] + A*C.dot(D)/A.dot(D)

func polygonCanSee(indices, vertices, a, b):
	if isLeftOn(vertices[value_at(indices, a+1)], vertices[indices[a]], vertices[indices[b]]) && isRightOn(vertices[value_at(indices, a - 1)], vertices[indices[a]], vertices[indices[b]]):
		return 0
	var p = vertices[indices[a]]-vertices[indices[b]]
	var sqdist = p.dot(p)
	for i in len(indices):
		if a == i or (i+1)%len(indices)==a:
			continue
		if isLeftOn(vertices[indices[a]], vertices[indices[b]], vertices[value_at(indices, i + 1)]) && isRightOn(vertices[indices[a]], vertices[indices[b]], vertices[indices[i]]):
			var l0 = [vertices[indices[a]], vertices[indices[b]]]
			var l1 = [vertices[indices[i]], vertices[value_at(indices, i + 1)]]
			p = l0[0] - lineInt(l0,l1)
			if p.dot(p) < sqdist:
				return 0
	return 1

func is_reflex(indices, vertices, i):
	return isRight(vertices[value_at(indices, i-1)], vertices[value_at(indices, i)], vertices[value_at(indices, i+1)])

func decomp(indices, vertices):
	var ndiag = INF
	var min = []
	for i0 in len(indices):
		if is_reflex(indices, vertices, i0) == 0:
			continue
		for i1 in range(i0 + 1, len(indices)):
			if polygonCanSee(indices, vertices, i0, i1):
				var left = []
				var right = []
				var j = i0
				while indices[i1] != indices[j]:
					left.append(indices[j])
					j -= 1
				j = i1
				while indices[i0] != indices[j]:
					right.append(indices[j])
					j -= 1
				var tmp = decomp(left, vertices).append_array(decomp(right, vertices))
				if len(tmp) < ndiag:
					ndiag = len(tmp)
					min = tmp
					min.append_array([indices[i0], indices[i1]])
	return min

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
	var skip = []
	skip.resize(len(loaded_verts))
	skip.fill(-1)
	
	#remove duplicate vertices
	var i = 0;
	for v0 in loaded_verts:
		if skip[i] == -1:
			skip[i] = i
			vertices.append(v0)
			for j in range(i+1, len(loaded_verts)):
				if v0 == loaded_verts[j]:
					skip[j] = i
		i += 1
	loaded_verts.clear()
	
	#reformat indices
	for i0 in range(0, len(skip), 3):
		indices[i0/3] = [skip[i0],skip[i0+1],skip[i0+2]]
	skip.clear()
	
	#calculate normals
	i = 0
	for index in indices:
		var v0 = vertices[index[0]]
		var v1 = vertices[index[1]]
		var v2 = vertices[index[2]]
		normals[i] = (v1 - v0).cross(v2 - v0).normalized()
		i += 1
		
	#merge faces by normals
	skip.resize(len(normals))
	skip.fill(0)
	var count = 0
	var same_plane = []
	i = 0
	for n0 in normals:
		if skip[i]:
			i += 1
			continue
		same_plane.append(indices[i])
		for j in range(i+1, len(normals)):
			#if it was already put in a plane ez skip
			if skip[j]:
				continue
			#if same normal and same plane
			if n0 == normals[j] and (vertices[indices[i][0]] - vertices[indices[j][0]]).dot(n0) == 0:
				same_plane[count].append_array(indices[j]) #add plane to
				skip[j] = 1
		i += 1
		count += 1
	var edges = []
	var outline = []
	var polygon = []
	for data in same_plane:
		edges.clear()
		outline.clear()
		polygon.clear()
		
		#only add edges once
		for p in data:
			var e = sort_edge(p[0],p[1])
			if edges.find(e) == -1:
				edges.append(e)
				outline.append([p[0],p[1]])
			e = sort_edge(p[1],p[2])
			if edges.find(e) == -1:
				edges.append(e)
				outline.append([p[1],p[2]])
			e = sort_edge(p[2],p[0])
			if edges.find(e) == -1:
				edges.append(e)
				outline.append([p[2],p[0]])
				
		#create polygon from edges
		var find = outline[0][1]
		var e = outline.pop_at(0)
		polygon.append_array(e)
		i = 0
		while i < len(outline):
			e = outline[i]
			if find == e[0]:
				outline.pop_at(i)
				polygon.append(e[0])
				find = e[1]
				i = 0
				continue
			if find == e[1]:
				outline.pop_at(i)
				polygon.append(e[1])
				find = e[0]
				i = 0
				continue
			i += 1
		edges = decomp(polygon, vertices)
		var new_polygon = []
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
