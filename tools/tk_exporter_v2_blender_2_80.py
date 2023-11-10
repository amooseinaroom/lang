
version = 2

bl_info = {
    "name": "Export TK Meshes and Animations",
    "description": "",
    "author": "Tafil Kajtazi",
    "version": (2, 0),
    "blender": (2, 80, 0),
    "location": "File > Export",
    "category": "Import-Export"}

import bpy
import math
import mathutils
import time
import os
import struct

from enum import IntEnum
from datetime import datetime

class Node:
    name = ""
    index = -1
    parent_index = -1
    depth = 0
    armature = None # for objects with armature modifier, not for bones
    node_to_parent_transform = mathutils.Matrix.Identity(4)
    node_to_world_transform = mathutils.Matrix.Identity(4)
    mesh_to_bone_transform = None
    blend_index = -1 # will be set if vertices need this node
    object = None
    
    # this garbage programming language!!!!!!
    # can't even assing list after creating an object
    def __init__(self):
        self.draw_commands = []

# includes object
def get_ancestors(object):
    path = [ object ]
            
    while object.parent:
        object = object.parent
        path.append(object)
        
    return reversed(path)

def add_bone_and_ancestors(bones, bone):
    bone_path = get_ancestors(bone)
                        
    for path_bone in bone_path:
        if not path_bone in bones:
            bones.append(path_bone)

def get_nodes(objects, only_deform_bones = True):
    nodes = []

    for object in objects:
        ancestors = get_ancestors(object)
        
        parent = None
        parent_index = -1
        parent_to_world_transform = mathutils.Matrix.Identity(4)
        parent_depth = 0
        
        # insert ancestors first
        for path_object in ancestors:
            index = -1
        
            for node in nodes:
                if path_object == node.object:
                    index = node.index
                    break
            
            if index == -1:
                index = len(nodes)
                node = Node()
                node.name = path_object.name
                
                node.node_to_world_transform = to_right_hand_column_matrix(path_object.matrix_world)
                
                print(node.name);
                
                # use bone to world transfrom to get node to parent transform
                # instead of armature to world transform
                if path_object.parent_type == 'BONE':
                    assert(path_object.parent.type == 'ARMATURE')
                    armature = path_object.parent.data
                    bone = armature.bones[path_object.parent_bone]
                    
                    bone_node = None
                    for test_node in nodes:
                        if test_node.object == bone:
                            bone_node = test_node
                            break
                    
                    # TODO: make shure that bones without deform but with object children, will allways be added to nodes
                    assert(bone_node)
                    node.node_to_parent_transform = node.node_to_world_transform @ bone_node.node_to_world_transform.inverted()
                    
                    node.parent_index = bone_node.index
                    node.depth        = bone_node.depth + 1
                    
                    print("bone parent");
                    print(bone.name);
                    print(bone_node.node_to_world_transform)
                else:
                    assert(not path_object.parent or (path_object.parent_type == 'OBJECT') or (path_object.parent_type == 'ARMATURE'))
                    
                    # node.node_to_parent_transform = parent_to_world_transform.inverted() @ node.node_to_world_transform
                    # order is swapped since we change from left column to right row matrices
                    # not shure why, but it seems to work
                    node.node_to_parent_transform = node.node_to_world_transform @ parent_to_world_transform.inverted()
                    
                    node.parent_index = parent_index
                    node.depth        = parent_depth + 1
                
                print("node to parent")
                print(node.node_to_parent_transform)
                print("node to world")
                print(node.node_to_world_transform)
                
                node.object = path_object
                node.index = index
                
                for modifier in path_object.modifiers:
                    if modifier.type == 'ARMATURE':
                        assert not node.armature, "only one armature modifier per mesh supported"
                        node.armature = modifier.object
                    
                nodes.append(node)
                
                # add armature bones
                if path_object.type == 'ARMATURE':
                    armature = path_object.data
                    
                    sorted_bones = []
                    
                    armature_to_world = node.node_to_world_transform
                    
                    for bone in armature.bones:
                        if not only_deform_bones or bone.use_deform:
                            add_bone_and_ancestors(sorted_bones, bone)
                    
                    for bone in sorted_bones:
                        # search parent bone or default to armature (node variable)
                        bone_parent_index = node.index
                        bone_parent_depth = node.depth
                        bone_parent_to_world = armature_to_world
                        
                        for test_node in nodes:
                            if test_node.object == bone.parent:
                                bone_parent_index = test_node.index
                                bone_parent_depth = test_node.depth
                                bone_parent_to_world = test_node.node_to_world_transform
                                break
                    
                        bone_node = Node()
                        # armature.name might be different from path_object.name
                        bone_node.name = path_object.name + '/' + bone.name
                        
                        # node matrix is relative to armature, so apply armature.node_to_world
                        # only transpose and swap yz without negation
                        # bone transforms are allready in right-hand, but we change z up to y up
                        # we convert from bone space to world space
                        bone_to_armature_transform = bone_to_right_hand_column_matrix(bone.matrix_local)
                       
                        # this is used for mesh skinning, so that each vertex can be transformed relative to the bone first
                        # bone_to_world @ mesh_to_bone_transform * vertex
                        bone_node.mesh_to_bone_transform   = bone_to_armature_transform.inverted()
                        
                        bone_node.node_to_world_transform  = armature_to_world @ bone_to_armature_transform
                        bone_node.node_to_parent_transform = bone_node.node_to_world_transform @ bone_parent_to_world.inverted()
                        
                        print("")
                        print(bone.name)
                        print(bone_to_armature_transform)
                        print(bone_node.node_to_world_transform)
                        print(bone_node.node_to_parent_transform)
                        print(bone_node.mesh_to_bone_transform)
                        
                        bone_node.object = bone
                        bone_node.index = len(nodes)
                        bone_node.parent_index = bone_parent_index
                        bone_node.depth        = bone_parent_depth + 1
                        nodes.append(bone_node)
            
            parent_to_world_transform = nodes[index].node_to_world_transform
            parent_depth = nodes[index].depth
            parent = path_object
            parent_index = index
    
    return nodes


def average_add(average, delta):
    average[0] += 1

    for i in range(3):
        average[i + 1] += delta[i]


def average_end(average):
    for i in range(3):
        average[i + 1] /= average[0]
        
# from blenders format to our format
        
def swap_yz(vector):
    return (vector[0], vector[2], -vector[1])


def negative(vector):
    return (-vector[0], -vector[1], -vector[2])
    

def to_right_hand_column_matrix(left_hand_row):
    left_hand_column  = left_hand_row.transposed()
    right_hand_column = mathutils.Matrix.Identity(4)
    
    right_hand_column[0][:-1] = swap_yz(left_hand_column[0][:-1])
    right_hand_column[1][:-1] = swap_yz(left_hand_column[2][:-1])
    right_hand_column[2][:-1] = negative( swap_yz(left_hand_column[1][:-1]) )
    right_hand_column[3][:-1] = swap_yz(left_hand_column[3][:-1])
    
    return right_hand_column

def bone_to_right_hand_column_matrix(left_hand_row):
    left_hand_column = left_hand_row.transposed()
    right_hand_column = left_hand_column.copy()
    
    # we don't need to negate colum[2] but otherwise same as to_right_hand_column_matrix
    right_hand_column[0][:-1] = swap_yz(left_hand_column[0][:-1])
    right_hand_column[1][:-1] = swap_yz(left_hand_column[1][:-1]) 
    right_hand_column[2][:-1] = swap_yz(left_hand_column[2][:-1])
    right_hand_column[3][:-1] = swap_yz(left_hand_column[3][:-1])
    
    return right_hand_column


# from our format to blenders format

def swap_zy(vector):
    return (vector[0], -vector[2], vector[1])
    
    
def to_left_hand_row_matrix(right_hand_column):
    right_hand_row = mathutils.Matrix.Identity(4)
    right_hand_row[0][:-1] = swap_zy(right_hand_column[0][:-1])
    right_hand_row[1][:-1] = swap_zy( negative(right_hand_column[2][:-1]) )
    right_hand_row[2][:-1] = swap_zy(right_hand_column[1][:-1])
    right_hand_row[3][:-1] = swap_zy(right_hand_column[3][:-1])
    
    left_hand_row = right_hand_row.transposed()
        
    return left_hand_row


class Mesh_Vertex:
    vertex_index  = -1
    polygon_index = -1
    loop_index    = -1


class Vertex:
    position      = (0, 0, 0)
    normal        = (0, 1, 0)
    tangent       = (1, 0, 0)
    color         = (1, 1, 1, 1)
    uv            = (0, 0)
    blend_weights = ( 1.0, 0.0, 0.0, 0.0 )
    blend_indices = (   0,   0,   0,   0 )
    

class Primitive(IntEnum):
    Points    = 0
    Lines     = 1
    Triangles = 2
    
Primitive_Names = [ "points", "lines", "triangles" ]

class Draw_Command:
    primitive    = Primitive.Triangles
    index_offset = 0
    index_count  = 0

# point input and output is a 3 float tupel
# transform is a mathutils.Matrix
def transform_point(transform, point):
    vector = mathutils.Vector((point[0], point[1], point[2], 1))
    vector = transform @ vector;
    result = (vector[0] / vector[3], vector[1] / vector[3], vector[2] / vector[3])
    
    return result;

# direction input and output is a 3 float tupel
# transform is a mathutils.Matrix
def transform_direction(transform, direction):
    vector = mathutils.Vector((direction[0], direction[1], direction[2], 0))
    vector = transform @ vector;
    #result = (vector[0] / vector[3], vector[1] / vector[3], vector[2] / vector[3])
    result = (vector[0], vector[1], vector[2])
    
    return result;


def insert_unique_vertex(unique_vertices, smooth_vertices, mesh, vertex_index, polygon_index, loop_index):
    vertex = Mesh_Vertex()
    vertex.vertex_index  = vertex_index
    vertex.polygon_index = polygon_index
    vertex.loop_index    = loop_index

    index = len(unique_vertices)

    # flat polygon vertices are allways unique
    if polygon_index != -1:
        unique_vertices.append(vertex)

        return index

    if loop_index != -1:
        vertex.vertex_index = mesh.loops[loop_index].vertex_index

    if vertex in smooth_vertices:
        return smooth_vertices[vertex]
    
    smooth_vertices[vertex] = index
    unique_vertices.append(vertex)

    return index


class tk_mesh_exporter(bpy.types.Operator):
    """Export TK Mesh"""                      # blender will use this as a tooltip for menu items and buttons.
    bl_idname = "object.tk_mesh_export"        # unique identifier for buttons and menu items to reference.
    bl_label = "TK Mesh (.tkm)"         # display name in the interface.

    filepath : bpy.props.StringProperty(subtype="FILE_PATH")
    filter_glob : bpy.props.StringProperty(default="*.tkm", options={'HIDDEN'})

    # export options ##########################################################

    only_selected_objects : bpy.props.BoolProperty(
        name        = "Export only selected objects",
        description = """""",
        default     = True,
        )

    apply_modifiers : bpy.props.BoolProperty(
        name        = "Apply visible Modifiers",
        description = "",
        default     = True,
        )

    with_tangents : bpy.props.BoolProperty(
        name        = "Export Tangents",
        description = """Add Vertex Attribute 'tangent' for all vertices.
                         (used for Normal Mapping)""",
        default     = False,
        )
        
    color_as_f32 : bpy.props.BoolProperty(
        name        = "Export Color as Floats",
        description = """Export Color values as single precision floats (32bit) instead of unsigend bytes (8bit) """,
        default     = False,
        )

    as_single_node : bpy.props.BoolProperty(
        name        = "Export as single Node",
        description = """Batch everything to a single Node using the Identity Transfrom.
                         (individual Objects will be preserved as seperate draw calls)""",
        default     = False,
        )
    
    only_deform_bones : bpy.props.BoolProperty(
        name        = "Export only deforming Bones",
        description = """Only bones with 'deform' enabled and their ancestors are exported.""",
        default     = True,
        )
        
    bake_current_pose : bpy.props.BoolProperty(
        name        = "Bake with current Pose",
        description = """Apply current Pose to Vertices""",
        default     = False,
        )

    binary_vertices_and_indices : bpy.props.BoolProperty(
        name        = "Export Vertices and Indices seperatly as Binary File",
        description = """Vertices and Indices will be exported seperatly in binary format as a '.tkb' file.
                         First all vertices followed by all indices without any padding and without counts.""",
        default     = False,
        )
    
    with_comments :  bpy.props.BoolProperty(
        name        = "Add comments to improve readabilty",
        description = """Inserts comments to describe the formating and describe the data more readably.""",
        default     = True,
        )

    def draw(self, context):
        layout = self.layout

        row = layout.row()
        row.prop(self, "only_selected_objects")

        row = layout.row()
        row.prop(self, "apply_modifiers")

        row = layout.row()
        row.prop(self, "with_tangents")
        
        row = layout.row()
        row.prop(self, "only_deform_bones")
        
        row = layout.row()
        row.prop(self, "color_as_f32")
        
        row = layout.row()
        row.prop(self, "binary_vertices_and_indices")
        
        row = layout.row()      
        row.prop(self, "as_single_node")
        
        row = layout.row()
        row.prop(self, "bake_current_pose")
        
        row = layout.row()
        row.prop(self, "with_comments")

    # formatting ##############################################################

    def open_array(self, count):
        self.write("%d { " % count)
        self.indentation += "    "

    def close_array(self):
        self.indentation = self.indentation[:-4]
        self.write("} ")

    def new_line(self):
        if self.new_line_pending:
            self.file.write("\n" + self.indentation)

        self.new_line_pending = True

    def write(self, text):
        if self.new_line_pending:
            self.file.write("\n" + self.indentation)
            self.new_line_pending = False

        self.file.write(text)
    
    # allways adds a new line
    def write_comment(self, text):
        if self.with_comments:
            self.write("# " + text)
            self.new_line()
    
    def comment_new_line(self):
        if self.with_comments:
            self.new_line()

    def write_export_time(self):
        # TODO: include timezone?
        now = datetime.now()
        self.write_comment("export time: " + now.strftime("%d.%m.%Y %H:%M:%S"))

    def write_draw_commands(self, node):		
        if not node.draw_commands or len(node.draw_commands) == 0:
            return    
        
        self.write("draw_commands ")
        self.open_array(len(node.draw_commands))
        self.new_line()
        
        for command in node.draw_commands:
            self.write("%s %d %d" % (Primitive_Names[command.primitive], command.index_offset, command.index_count))
            self.new_line()

        self.close_array() # draw_commands
        self.new_line()

    def write_indices(self, indices, label, indices_per_primitive, primitives_per_line):
        if len(indices) == 0:
            return

        index_count = 0
        primitives_in_line_count = 0

        self.new_line()
        self.write_comment("%d %s total" % (len(indices) / indices_per_primitive, label));
        self.write_comment("%d %s per row" % (primitives_per_line, label));

        for i in indices:
            self.write("%d" % i)

            index_count += 1
            if index_count == indices_per_primitive:
                index_count = 0
                primitives_in_line_count += 1

                if primitives_in_line_count == primitives_per_line:
                    primitives_in_line_count = 0
                    self.new_line()
                else:
                    self.write("   ")
            else:
                self.write(" ")

    def execute(self, context):
        # reset temporary data here, stored in class to avoid passing around
        self.indentation = ""
        self.file = None
        self.new_line_pending = False       

        self.with_color = False
        self.with_uvs = False
        self.with_blending = False
        
        nodes = {}
        vertices = []
        triangles = []
        lines = []
        points = []

        start_time = time.time()
        
        armature_state_backups = {}
        
        for object in bpy.data.objects:
            if object.type == 'ARMATURE':
                armature_state_backups[object] = object.data.pose_position
                
                if self.bake_current_pose:
                    object.data.pose_position = 'POSE'
                else:
                    object.data.pose_position = 'REST'
        
        if self.only_selected_objects:
            nodes = get_nodes(context.selected_objects, self.only_deform_bones)
        else:
            nodes = get_nodes(bpy.data.objects, self.only_deform_bones)
        
        # get dependancy graph with changed modifiers
        depsgraph = bpy.context.evaluated_depsgraph_get()
        
        # to cache instances of same mesh data, if not as_single_node
        object_data_to_node_map = {}
        
        # assign blend_index to nodes used for vertex blending
        blend_node_count = 0
        
        # collect mesh data
        for node in nodes:
            object = node.object
            
            if isinstance(object, bpy.types.Bone):
                continue
            
            if object.type != 'MESH' and object.type != 'CURVE':
                continue
            
            triangle_count = len(triangles)
            line_count = len(lines)
            point_count = len(points)
            
            # total change from belnder 2.79
            if self.apply_modifiers:
                evaluated_object = object.evaluated_get(depsgraph)
            else:
                evaluated_object = object

            mesh = evaluated_object.to_mesh()            
            
            if self.as_single_node:                             
                to_node_transform = to_left_hand_row_matrix(node.node_to_world_transform)
                mesh.transform(to_node_transform)
                mesh.update()
            
            # this mesh was allready exported
            elif object.data in object_data_to_node_map:
                other_node = object_data_to_node_map[object.data]
                node.draw_commands = other_node.draw_commands
                continue                                   
                            
            mesh.calc_normals_split()
            has_uv = mesh.uv_layers.active != None
            
            active_uvs = None
            if has_uv:
                active_uvs = mesh.uv_layers.active.data

            if has_uv and len(active_uvs) and self.with_tangents:
                mesh.calc_tangents()
                            
            unique_vertices = []
            smooth_vertices = {}
                    
            vertex_offset = len(vertices)

            for polygon in mesh.polygons:
                polygon_index = polygon.index
                if polygon.use_smooth:
                    polygon_index = -1

                indices = []
                
                for vertex_index, loop_index in zip(polygon.vertices, polygon.loop_indices):
                    indices.append(vertex_offset + insert_unique_vertex(unique_vertices, smooth_vertices, mesh, vertex_index, polygon_index, loop_index))
                
                assert len(polygon.vertices) > 2, "polygons are expected to have at least 3 vertices"
                count = len(indices)
                half  = count // 2
                # (count - 2) // 2
                # 3 -> 0
                # 4 -> 1 
                # 5 -> 1
                # 6 -> 2 etc.
                for i in range(half - 1):
                    triangles.append(indices[i])
                    triangles.append(indices[i + 1])
                    triangles.append(indices[count - 1 - i])
                    
                    triangles.append(indices[i + 1])
                    triangles.append(indices[count - 2 - i])
                    triangles.append(indices[count - 1 - i])

                if (count % 2) > 0:                 
                    triangles.append(indices[half - 1])
                    triangles.append(indices[half])
                    triangles.append(indices[half + 1])
           
            for edge in mesh.edges:
                if not edge.is_loose:
                    continue

                for vertex_index in edge.vertices:
                    index = vertex_offset + insert_unique_vertex(unique_vertices, smooth_vertices, mesh, vertex_index, -1, -1)
                    lines.append(index)

            for unique_vertex in unique_vertices:
                vertex_index  = unique_vertex.vertex_index
                polygon_index = unique_vertex.polygon_index
                loop_index    = unique_vertex.loop_index
                
                vertex = Vertex()
                
                if polygon_index != -1:
                    vertex.normal  = swap_yz(mesh.polygons[polygon_index].normal[:])
                else:
                    vertex.normal  = swap_yz(mesh.vertices[vertex_index].normal[:])
                                            
                vertex.position = swap_yz(mesh.vertices[vertex_index].co[:])

                if loop_index != -1:
                    vertex.tangent = swap_yz(mesh.loops[loop_index].tangent[:])
                
                if active_uvs:
                    vertex.uv = (active_uvs[loop_index].uv[:])

                if mesh.vertex_colors:
                    vertex.color = (mesh.vertex_colors[0].data[loop_index].color[:])            
                
                
                if node.armature and len(evaluated_object.vertex_groups) > 0:
                    # tupels of (blend_weight, bone_index)
                    # bone[0] is blend_weight, bone[1] is bone index, see bone_element below
                    bones = []
                    
                    for group_element in mesh.vertices[vertex_index].groups:
                        # self.report({'INFO'}, "vertex: %d, bone: %s" % (vertex_index, evaluated_object.vertex_groups[group_element.group].name))
                        
                        bone_name = node.armature.name + "/" + evaluated_object.vertex_groups[group_element.group].name
                        bone_node = None
                        
                        for bone_node_it in nodes:
                            if bone_node_it.name == bone_name:
                                bone_node = bone_node_it
                                break
                        
                        assert(bone_node)
                        
                        # bone_node was not used for blending yet
                        if bone_node.blend_index == -1:
                            bone_node.blend_index = blend_node_count
                            blend_node_count += 1
                        
                        assert bone_node.index < 256, "bones indices are encoded with 1 byte, more thern 256 bones are not supported for now"
                        bones.append((group_element.weight, bone_node.blend_index))

                    if len(bones) > 4:
                        self.report({'WARNING'}, "warning: vertex belongs to more then 4 vertex groups, only the top 4 groups with the highest weights will be used")
                        # search for the top 4 most influential bones and only use them
                        bones = sorted(bones, key=lambda bone_element: bone_element[0])[0:3]

                    # normalize bone_weight so that the total_weight of the top 4 bones adds up to 1.0
                    
                    total_weight = 0.0
                    for bone_element in bones:
                        total_weight += bone_element[0]
                    
                    if total_weight > 0.0:
                        for i in range(len(bones)):
                            bones[i] = (bones[i][0] / total_weight, bones[i][1]);

                    # use the armature node if we have no bones
                    if len(bones) == 0:
                        # armature node was not used for blending yet
                        if node.blend_index == -1:
                            node.blend_index = blend_node_count
                            blend_node_count += 1
                    
                        bones.append((1.0, node.blend_index))
                        
                    while len(bones) < 4:
                        bones.append((0.0, 0))

                    vertex.blend_weights = ( bones[0][0], bones[1][0], bones[2][0], bones[3][0] )
                    vertex.blend_indices = ( bones[0][1], bones[1][1], bones[2][1], bones[3][1] )                
                
                vertices.append(vertex)

            #NOTE: index_offset will be adjusted, once we know how mucht indices we have in total

            if len(triangles) - triangle_count > 0:
                command = Draw_Command()
                command.primitive    = Primitive.Triangles
                command.index_offset = triangle_count
                command.index_count  = len(triangles) - triangle_count
                node.draw_commands.append(command)

            if len(lines) - line_count > 0:
                command = Draw_Command()
                command.primitive    = Primitive.Lines
                command.index_offset = line_count
                command.index_count  = len(lines) - line_count
                node.draw_commands.append(command)

            if len(points) - point_count > 0:
                command = Draw_Command()
                command.primitive    = Primitive.Points
                command.index_offset = point_count
                command.index_count  = len(points) - point_count
                node.draw_commands.append(command)
            
            if len(node.draw_commands) > 0:            
                if mesh.vertex_colors:
                    self.with_color = True

                if mesh.uv_layers:
                    self.with_uvs = True

                if len(evaluated_object.vertex_groups) > 0:
                    self.with_blending = True
        
                self.report({'INFO'}, "%s unique vertex count: %d, triangle count: %d" % (evaluated_object.name, len(unique_vertices), node.draw_commands[0].index_count // 3))
            
            if not self.as_single_node:
                object_data_to_node_map[object.data] = node

        blend_node_indices = [-1] * blend_node_count

        # update offsets
        # first all triangles, then all lines, then all points
        for node in nodes:
        
            if node.blend_index != -1:
                blend_node_indices[node.blend_index] = node.index
        
            if not node.draw_commands:
                continue
            
            for command in node.draw_commands:
                if command.primitive == Primitive.Lines:
                    command.index_offset += len(triangles)
                elif command.primitive == Primitive.Points:
                    command.index_offset += len(triangles) + len(lines)				

        if self.as_single_node:
            single_node = Node()
            single_node.name = "root"
            single_node.depth = 1
            single_node.index = 0;
            
            for node in nodes:
                single_node.draw_commands.extend(node.draw_commands)
                
            nodes = [ single_node ]
            blend_node_indices = [ ]
                
        max_depth = 0
        for node in nodes:
            max_depth = max(max_depth, node.depth)
        
        build_time = time.time() - start_time
        self.report({'INFO'}, "build time: %f" % build_time)

        filepath = os.path.splitext(self.filepath)[0] + ".tkm"
        
        self.file = open(filepath, 'w')

        self.write_comment("tk mesh")
        self.write_export_time()
        self.comment_new_line()

        self.write("version %i" % version)
        self.new_line()
        self.new_line()

        draw_command_count = 0
        names_byte_count = 0

        for node in nodes:
            if node.draw_commands:
                draw_command_count += len(node.draw_commands)

            names_byte_count += len(node.name)

        self.write_comment("'nodes' max_depth draw_command_count names_byte_count node_count { ... }")
        
        self.write("nodes ")
        self.write("%i " % max_depth)
        self.write("%i " % draw_command_count)
        self.write("%i " % names_byte_count)
        self.open_array(len(nodes))
        
        self.comment_new_line()
        self.write_comment("name parent_index depth")
        self.write_comment("node_to_parent_transform")
        self.write_comment("optional 'mesh_to_bone' blend_index (used for skinning, transforms vertex to bone space, before applying bone pose)")
        self.write_comment("optional 'draw_commands' draw_command_count { primitive index_offset index_count ... } ")
        self.write_comment("optional 'sphere' radius")
        self.write_comment("optional 'circle' radius")
        
        for node in nodes:
            self.new_line()
            
            if node.parent_index != -1:
                self.write_comment('node %i parent %i "%s"' % (node.index, node.parent_index, nodes[node.parent_index].name))
            else:
                self.write_comment('node %i parent %i none' % (node.index, node.parent_index))
            
            self.write('"%s" %i %i' % (node.name, node.parent_index, node.depth))
            self.new_line()

            self.write("%.6f %.6f %.6f " % node.node_to_parent_transform[0][:-1])
            self.new_line()
            self.write("%.6f %.6f %.6f " % node.node_to_parent_transform[1][:-1])
            self.new_line()
            self.write("%.6f %.6f %.6f " % node.node_to_parent_transform[2][:-1])
            self.new_line()
            self.write("%.6f %.6f %.6f " % node.node_to_parent_transform[3][:-1])
            self.new_line()
                
            if node.mesh_to_bone_transform and (node.blend_index != -1):
                self.write("mesh_to_bone %i " % node.blend_index);
                self.new_line()
                self.write("%.6f %.6f %.6f " % node.mesh_to_bone_transform[0][:-1])
                self.new_line()
                self.write("%.6f %.6f %.6f " % node.mesh_to_bone_transform[1][:-1])
                self.new_line()
                self.write("%.6f %.6f %.6f " % node.mesh_to_bone_transform[2][:-1])
                self.new_line()
                self.write("%.6f %.6f %.6f " % node.mesh_to_bone_transform[3][:-1])
                self.new_line()

            self.write_draw_commands(node)
            
            # could be None if we export as single node
            if node.object and not isinstance(node.object, bpy.types.Bone):
                if node.object.type == 'EMPTY':
                    if node.object.empty_display_type == 'SPHERE':
                        self.write("sphere %.6f" % node.object.empty_display_size)
                        self.new_line()
                    elif node.object.empty_display_type == 'CIRCLE':
                        self.write("circle %.6f" % node.object.empty_display_size)
                        self.new_line()
            
        self.close_array() # nodes
        self.new_line()
        self.new_line()
        
        self.write_comment("'blend_node_indices' blend_node_count { ... }")
        
        self.write("blend_node_indices ")
        self.open_array(len(blend_node_indices))
        self.new_line()
        
        blend_indices_per_row = 4
        
        for i, index in enumerate(blend_node_indices):
            if (i != 0) and ((i % blend_indices_per_row) == 0):
                self.new_line()
                
            self.write("%i " % index)
            self.write_comment('"%s"' % nodes[index].name)
        
        self.close_array() # blend_node_indices
        self.new_line()
        self.new_line()
        
        attribue_count = 2 # has at least position, normal

        if self.with_tangents:
            attribue_count += 1

        if self.with_color:
            attribue_count += 1

        if self.with_uvs:
            attribue_count += 1

        # if the current pose is baked, we dont export blending information
        if self.bake_current_pose:
            self.with_blending = False

        if self.with_blending:
            attribue_count += 2

        self.write_comment("'vertices' vertex_attribute_count { ... } vertex_count { ... }")
            
        self.write("vertices ")
        self.open_array(attribue_count)
        self.new_line()

        self.write_comment("attribute type ")

        self.write("position v3f32")
        self.new_line()

        self.write("normal v3f32")
        self.new_line()

        if self.with_tangents:
            self.write("tangent v3f32")
            self.new_line()

        if self.with_uvs:
            self.write("uv v2f32")
            self.new_line()

        if self.with_blending:
            self.write("blend_indices v4u8") # these are indices and should not be mapped to 0 to 1
            self.new_line()
            self.write("blend_weights v4f32")
            self.new_line()
        
        if self.with_color:
            self.write("color ")
            if self.color_as_f32:
                self.write("v4f32")
            else:
                self.write("rgba8") # indicate that the value should be mapped to 0 to 1
            self.new_line()

        self.close_array()
        
        if self.binary_vertices_and_indices:
            self.write("%d binary" % len(vertices));
        else:               
            self.open_array(len(vertices))
            self.new_line()
            
            format_comment = "position.x position.y position.z  "
                            
            format_comment += "normal.x normal.y normal.z  "
            
            if self.with_tangents:
                format_comment += "tangent.x tangent.y tangent.z  "
                
            if self.with_uvs:
                format_comment += "uvs.x uvs.y  "
                
            if self.with_blending:
                format_comment += "blend_indices_type blend_indices_count  "
                format_comment += "blend_weights[0 .. blend_indcides_count - 1]  "
            
            if self.with_color:
                format_comment += "color.r color.g color.b color.a  "
            
            self.write_comment(format_comment)
            self.comment_new_line()
                         
            for vertex in vertices:     
                self.write("%.6f %.6f %.6f  " % vertex.position)
                               
                self.write("%.6f %.6f %.6f  " % vertex.normal)
                
                if self.with_tangents:
                    self.write("%.6f %.6f %.6f  " % vertex.tangent)
                    
                if self.with_uvs:
                    self.write("%.6f %.6f  " % vertex.uv)
                    
                if self.with_blending:          
                    self.write("u8 4 %d %d %d %d  " % vertex.blend_indices)
                    self.write("%.6f %.6f %.6f %.6f  " % vertex.blend_weights)

                if self.with_color:
                    if self.color_as_f32:
                        self.write("%.6f %.6f %.6f %.6f " % vertex.color)
                    else:
                        self.write("u8 4 %d %d %d %d " % (int(255 * vertex.color[0]), int(255 * vertex.color[1]), int(255 * vertex.color[2]), int(255 * vertex.color[3])))
                    
                self.new_line()
            
            self.close_array() # vertices
        
        self.new_line()
        self.new_line()
        
        self.write_comment("'indices' triangle_index_count line_index_count point_index_count index_count { ... }")
        
        self.write("indices %d %d %d " % (len(triangles), len(lines), len(points)))

        if self.binary_vertices_and_indices:
            self.write("%d binary" % (len(triangles) + len(lines) + len(points)));
        else:        
            self.open_array(len(triangles) + len(lines) + len(points))

            self.write_indices(triangles, "triangles", 3, 4)
            self.write_indices(lines, "lines", 2, 6)
            self.write_indices(points, "points", 1, 12)

            self.close_array() # indices
            
        self.new_line()

        self.file.close()
        
        if self.binary_vertices_and_indices:
            path, extension = os.path.splitext(filepath)
            binary_filepath = path + ".tkb"
                        
            print(binary_filepath)                                 
            binary_file = open(binary_filepath, 'wb')
            
            bytes = bytearray()
            
            for vertex in vertices:                
                bytes.extend(struct.pack("fff", *vertex.position))              
                                                
                bytes.extend(struct.pack("fff", *vertex.normal))
                
                if self.with_tangents:
                    bytes.extend(struct.pack("fff", *vertex.tangent))
                    
                if self.with_uvs:
                    bytes.extend(struct.pack("ff", *vertex.uv))
                    
                if self.with_blending:          
                    bytes.extend(vertex.blend_indices)
                    bytes.extend(struct.pack("ffff", *vertex.blend_weights))
                
                if self.with_color:
                    if self.color_as_f32:
                        bytes.extend(struct.pack("ffff", *vertex.color))
                    else:
                        bytes.extend(struct.pack("BBBB", int(255 * vertex.color[0]), int(255 * vertex.color[1]), int(255 * vertex.color[2]), int(255 * vertex.color[3])) )
                                    
            for index in triangles:
                bytes.extend(struct.pack("I", index))
                
            for index in lines:
                bytes.extend(struct.pack("I", index))
                
            for index in points:
                bytes.extend(struct.pack("I", index))            
                
            binary_file.write(bytes)
            binary_file.close()            
        
        # reload original armature pose
        for object in bpy.data.objects:
            if object.type == 'ARMATURE':
                object.data.pose_position = armature_state_backups[object]

        write_time = time.time() - start_time - build_time
        self.report({'INFO'}, "write time %f" % write_time)
        self.report({'INFO'}, "DONE: node count: %d, vertex count: %d, triangle count: %d, line count: %d, point count: %d" % (len(nodes), len(vertices), len(triangles) / 3, len(lines) / 2, len(points)))

        if len(nodes) == 0:
            self.report({'WARNING'}, "warning: no nodes exported (maybe you didn't select a mesh)")

        return {'FINISHED'}


    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

class tk_sampled_animation_exporter(bpy.types.Operator):
    """Export TK Sampled Animations"""               # blender will use this as a tooltip for menu items and buttons.
    bl_idname = "object.tk_sampled_animation_export" # unique identifier for buttons and menu items to reference.
    bl_label = "TK Sampled Animations (.tka)" # display name in the interface.

    filepath : bpy.props.StringProperty(subtype="FILE_PATH")
    filter_glob : bpy.props.StringProperty(default="*.tka", options={'HIDDEN'})

    # export options ##########################################################
    
    # HACK: copied from tk_mesh_exporter
    with_comments :  bpy.props.BoolProperty(
        name        = "Add comments to improve readabilty",
        description = """Inserts comments to describe the formating and describe the data more readably.""",
        default     = True,
        )

    def draw(self, context):
        layout = self.layout

        row = layout.row()
        row.prop(self, "with_comments")

    # HACK: copied from tk_mesh_exporter
    # formatting ##############################################################

    def open_array(self, count):
        self.write("%d { " % count)
        self.indentation += "    "

    def close_array(self):
        self.indentation = self.indentation[:-4]
        self.write("} ")

    def new_line(self):
        if self.new_line_pending:
            self.file.write("\n" + self.indentation)

        self.new_line_pending = True

    def write(self, text):
        if self.new_line_pending:
            self.file.write("\n" + self.indentation)
            self.new_line_pending = False

        self.file.write(text)
    
    # allways adds a new line
    def write_comment(self, text = ""):
        if self.with_comments:
            self.write("# " + text)
            self.new_line()
            
    def comment_new_line(self):
        if self.with_comments:
            self.new_line()

    def write_export_time(self):
        # TODO: include timezone?
        now = datetime.now()
        self.write_comment("export time: " + now.strftime("%d.%m.%Y %H:%M:%S"))

    def execute(self, context):
        start_time = time.time()
        
        # reset temporary data here, stored in class to avoid passing around
        self.indentation = ""
        self.file = None
        self.new_line_pending = False       
        
        backup_scene_frame = bpy.context.scene.frame_current
        
        filepath = os.path.splitext(self.filepath)[0] + ".tka"
        
        self.file = open(filepath, 'w')
        
        self.write_comment("tk sampled animations")
        self.write_export_time()
        self.comment_new_line()
        
        self.write("version 1")
        self.new_line()
        self.new_line()
        
        frames_per_second = bpy.context.scene.render.fps
        self.write("frames_per_second %d" % frames_per_second)
        self.new_line()
        self.new_line()
        
        armature_objects = []
        for object in context.selected_objects:
            if object.type == 'ARMATURE':
                armature_objects.append(object)
                
        actions = bpy.data.actions
        
        animation_count = 0
        for action in actions:
            if len(action.fcurves) == 0:
                continue
            
            animation_count += 1
        
        # we can't really now wich animation goes with wich armature so we just export the cross product
        self.write_comment("'animations' animation_count { ... }")
        self.write("animations ")
        self.open_array(animation_count * len(armature_objects))
        
        self.comment_new_line()
        self.write_comment("'animation' name channel_count { ... }")
        self.write_comment("'frames' start_frame frame_count duration_in_seconds value_count { ... }")
        
        # iterate over all armatures
        # iterate over all actions
        # set armature action to current action
        # sample animation
        # restore armature settins
        
        for object in armature_objects:
            # pose and action are part of the object
            # while bones is part of object.data (armature)
            armature = object.data
            
            object_action_backup = object.animation_data.action
            
            # set armature to pose, otherwise we only export identity transforms
            armature_pose_position_backup = armature.pose_position
            armature.pose_position = 'POSE'

            for action in actions:
                if len(action.fcurves) == 0:
                    continue
                    
                # set current action
                object.animation_data.action = action
                    
                # find start and end frame
                # initial values, so that we have valid bounds while searching min and max
                action_frame_start, action_frame_end = action.fcurves[0].range()
                for curve in action.fcurves:
                    start, end = curve.range()
                    action_frame_start = min(action_frame_start, start)
                    action_frame_end   = max(action_frame_end,   end)
                
                # WARNING: object.name and armature.name might be different
                self.new_line()
                self.write('animation "%s/%s" ' % (object.name, action.name))
                
                self.open_array(len(armature.bones))
                self.new_line()
                
                self.write_comment("channel_name optional 'translation' optional 'rotation' optional 'scale'")
                self.comment_new_line()
                
                values_per_frame = 0
                
                for bone in armature.bones:
                    values_per_frame += 10
                
                    self.write('"%s/%s" ' % (object.name, bone.name))
                    self.write('translation rotation scale')
                    self.new_line()
                
                self.close_array()
                self.new_line()
                
                # action_frame_end is not included
                frame_count = int(action_frame_end - action_frame_start + 1)
                self.write("frames %d %d %.2f " % (int(action_frame_start), frame_count, float(frame_count) / frames_per_second))
                self.open_array(values_per_frame * frame_count)
            
                # first frame is relative to rest pose, to handle quaternion double cover
                previous_frame_rotations = []
                for bone in armature.bones:
                    rest_translation, rest_rotation, rest_scale = bone.matrix_local.decompose()
                    previous_frame_rotations.append(rest_rotation)
            
                for frame in range(int(action_frame_start), int(action_frame_end) + 1):
                
                    bpy.context.scene.frame_set(frame)
                
                    self.new_line()
                    
                    self.write_comment("frame %i" % frame)
                    
                    for bone_index, bone in enumerate(armature.bones):
                        # order of pose bones might be different from bones
                        # we allways go in order of the bones
                        pose_bone = object.pose.bones[bone.name]
                        
                        if bone.parent:
                            parent_pose_bone = object.pose.bones[bone.parent.name]
                            
                            # we want the delta
                            # bone_pose = parent_pose * parent_to_bone_rest * delta
                            #           = parent_pose * parent_rest.inverted() * bone_rest * delta
                            # <=>
                            # bone_rest.inverted() * parent_rest * parent_pose.inverted() * bone_pose = delta
                            
                            delta = bone.matrix_local.inverted() @ bone.parent.matrix_local @ parent_pose_bone.matrix.inverted() @ pose_bone.matrix
                        else:
                            delta = bone.matrix_local.inverted() @ pose_bone.matrix
                        
                        translation, rotation, scale = delta.decompose()
                        
                        # handle quaternion double cover by looking at previous frame rotation
                        previous_rotation = previous_frame_rotations[bone_index]
                        
                        if (mathutils.Quaternion(previous_rotation).dot(mathutils.Quaternion(rotation)) < 0):
                            rotation[0] = -rotation[0]
                            rotation[1] = -rotation[1]
                            rotation[2] = -rotation[2]
                            rotation[3] = -rotation[3]
                        
                        previous_frame_rotations[bone_index] = rotation
                    
                        self.write_comment('"%s/%s" ' % (object.name, bone.name))
                        
                        # no need to convert from z up to y up, since bone transfroms are allready in right hand coordinates
                        self.write("%.6f %.6f %.6f "      % tuple(translation))
                        self.write("%.6f %.6f %.6f %.6f " % (rotation[0], rotation[1], rotation[2], rotation[3]))
                        self.write("%.6f %.6f %.6f "      % tuple(scale))
    
                        self.new_line()
                    
                self.close_array()
                self.new_line()
                
                #restore action and pose
                object.animation_data.action = object_action_backup
                armature.pose_position       = armature_pose_position_backup

        self.close_array()
                
        self.file.close()
        
        bpy.context.scene.frame_set(backup_scene_frame)

        write_time = time.time() - start_time
        self.report({'INFO'}, "write time %f" % write_time)

        return {'FINISHED'}


    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}


# only needed if you want to add into a dynamic menu
def mesh_menu_func(self, context):
    self.layout.operator_context = 'INVOKE_DEFAULT'
    self.layout.operator(tk_mesh_exporter.bl_idname, text=tk_mesh_exporter.bl_label)

def animation_menu_func(self, context):
    self.layout.operator_context = 'INVOKE_DEFAULT'
    self.layout.operator(tk_sampled_animation_exporter.bl_idname, text=tk_sampled_animation_exporter.bl_label)


def register():
    bpy.utils.register_class(tk_mesh_exporter)
    bpy.types.TOPBAR_MT_file_export.append(mesh_menu_func)
    
    bpy.utils.register_class(tk_sampled_animation_exporter)
    bpy.types.TOPBAR_MT_file_export.append(animation_menu_func)


def unregister():
    bpy.types.TOPBAR_MT_file_export.remove(mesh_menu_func)
    bpy.utils.unregister_class(tk_mesh_exporter)

    bpy.types.TOPBAR_MT_file_export.remove(animation_menu_func)
    bpy.utils.unregister_class(tk_sampled_animation_exporter)


if __name__ == "__main__":
    register()
    
    do_test_mesh       = False
    do_test_animation  = False
    test_with_comments = True
    test_filepath  = "D:/work/collision_system/data/test"
    #test_filepath = "D:/work/collision_system/data/dude2"
    
    if do_test_mesh:
        use_binary_vertices_and_indices = False
        with_tangents = True
        color_as_f32 = False
        bpy.ops.object.tk_mesh_export(filepath = test_filepath + "_single", as_single_node = True, color_as_f32 = color_as_f32, binary_vertices_and_indices = use_binary_vertices_and_indices, with_comments = test_with_comments, with_tangents = with_tangents)
        bpy.ops.object.tk_mesh_export(filepath = test_filepath, as_single_node = False, binary_vertices_and_indices = use_binary_vertices_and_indices, with_comments = test_with_comments, with_tangents = with_tangents)
    
    if do_test_animation:
        bpy.ops.object.tk_sampled_animation_export(filepath = test_filepath, with_comments = test_with_comments)
        
    if do_test_mesh or do_test_animation:
        unregister()
