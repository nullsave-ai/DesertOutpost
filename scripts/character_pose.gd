class_name CharacterPose
## Simple procedural poses for the imported 54-bone humanoid (the GLB ships no clips).
static func relax_arms(root: Node, down_deg := 68.0, elbow_deg := 14.0) -> void:
	for sk in root.find_children("*", "Skeleton3D", true, false):
		var s := sk as Skeleton3D
		for side in [["Left", -1.0], ["Right", 1.0]]:
			var i := s.find_bone(side[0] + "UpperArm"); var j := s.find_bone(side[0] + "LowerArm")
			if i >= 0: s.set_bone_pose_rotation(i, s.get_bone_rest(i).basis.get_rotation_quaternion() * Quaternion(Vector3(0, 0, 1), deg_to_rad(down_deg * side[1])))
			if j >= 0: s.set_bone_pose_rotation(j, s.get_bone_rest(j).basis.get_rotation_quaternion() * Quaternion(Vector3(0, 1, 0), deg_to_rad(elbow_deg * side[1])))
