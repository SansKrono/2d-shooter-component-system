class_name Tool3D

static var mesh_material_original 
static var mesh_material_new
static var materials := []


static func get_materials(node: Node, reset := false) -> Array:
	materials = []
	if node is Node3D:
		
		if node is MeshInstance3D:
			if reset:
				back_to_original_materials(node)
			else:
				copy_and_apply_materials(node)
		
		if node.get_children().size() > 0:
			for child in node.get_children():
				if child is MeshInstance3D:
					if reset:
						back_to_original_materials(child)
					else:
						copy_and_apply_materials(child)
					
				if child.get_children().size() > 0:
					for grandchild in child.get_children():
						if grandchild is MeshInstance3D:
							if reset:
								back_to_original_materials(grandchild)
							else:
								copy_and_apply_materials(grandchild)
							
						if grandchild.get_children().size() > 0:
							for greatgrandchild in grandchild.get_children():
								if greatgrandchild is MeshInstance3D:
									if reset:
										back_to_original_materials(greatgrandchild)
									else:
										copy_and_apply_materials(greatgrandchild)
	else:
		# ERROR - NODE NOT 3D
		push_error("NodeFX: Node must be Node3D to get its materials")
	
	return materials
	

static func save_original_materials(mesh):
	var surface_count = mesh.mesh.get_surface_count()
	NodeFX.ORIGINAL_MATERIALS[mesh] = []
	
	for s in range(surface_count):
		mesh_material_original = mesh.get_active_material(s)
		
		if is_instance_valid(mesh_material_original):
			NodeFX.ORIGINAL_MATERIALS[mesh].append(mesh_material_original)


static func copy_and_apply_materials(mesh):
	if NodeFX.ORIGINAL_MATERIALS.is_empty() or not NodeFX.ORIGINAL_MATERIALS.has(mesh):
		save_original_materials(mesh)
		
	var surface_count = mesh.mesh.get_surface_count()
	for s in range(surface_count):
		mesh_material_original = NodeFX.ORIGINAL_MATERIALS[mesh][s]
		
		if is_instance_valid(mesh_material_original):
			mesh_material_new = mesh_material_original.duplicate(true)
			mesh_material_new.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			if surface_count > 1:
				mesh_material_new.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh_material_new.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		else:
			mesh_material_new = StandardMaterial3D.new()
			mesh_material_new.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_material_new.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh_material_new.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mesh.set_surface_override_material(s, mesh_material_new)
		materials.append(mesh_material_new)


static func back_to_original_materials(mesh):
	if not NodeFX.ORIGINAL_MATERIALS.is_empty():
		var surface_count = mesh.mesh.get_surface_count()
		
		for s in range(surface_count):
			if NodeFX.ORIGINAL_MATERIALS.has(mesh):
				mesh_material_original = NodeFX.ORIGINAL_MATERIALS[mesh][s]
				
				if is_instance_valid(mesh_material_original):
					mesh.set_surface_override_material(s, mesh_material_original)
