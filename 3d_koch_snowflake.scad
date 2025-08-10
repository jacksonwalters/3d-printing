// Parameters
size = 30;
nozzle_width = 0.4;
scale_factor = 0.5;
recursion_depth = 2;

// Vector helpers
function v_sub(a,b) = [a[0]-b[0], a[1]-b[1], a[2]-b[2]];
function cross(a,b) = [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]];
function dot(a,b) = a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
function norm(v) = sqrt(dot(v,v));
function normalize(v) = let(n=norm(v)) (n==0 ? [0,0,0] : [v[0]/n,v[1]/n,v[2]/n]);

// Calculate face normal (pointing outward from tetrahedron center)
function face_normal(v1, v2, v3, center) = 
    let(
        normal_raw = cross(v_sub(v2, v1), v_sub(v3, v1)),
        face_center = [(v1[0]+v2[0]+v3[0])/3, (v1[1]+v2[1]+v3[1])/3, (v1[2]+v2[2]+v3[2])/3],
        to_face = v_sub(face_center, center)
    )
    dot(normal_raw, to_face) > 0 ? normalize(normal_raw) : normalize([-normal_raw[0], -normal_raw[1], -normal_raw[2]]);

// Convert direction vector to Euler angles
function vector_to_euler(vec) = 
    let(
        v = normalize(vec),
        // Calculate rotation angles to align z-axis with vec
        xy_len = sqrt(v[0]*v[0] + v[1]*v[1]),
        rot_y = xy_len > 0.001 ? atan2(v[0], v[2]) : 0,
        rot_x = atan2(-v[1], sqrt(v[0]*v[0] + v[2]*v[2]))
    )
    [rot_x, rot_y, 0];

module tetra(s) {
    points = [
        [0, 0, 0],
        [s, 0, 0],
        [s/2, (sqrt(3)/2)*s, 0],
        [s/2, (sqrt(3)/6)*s, sqrt(6)/3 * s]
    ];
    faces = [
        [0, 1, 2],  // base
        [0, 1, 3],  // side 1
        [1, 2, 3],  // side 2
        [2, 0, 3]   // side 3
    ];
    polyhedron(points=points, faces=faces);
}

// Recursive fractal
module fractal_tetra(s, depth) {
    if (s >= nozzle_width && depth > 0) {
        tetra(s);
        
        next_size = s * scale_factor;
        if (next_size >= nozzle_width && depth > 1) {
            // Tetrahedron vertices
            v0 = [0, 0, 0];
            v1 = [s, 0, 0];
            v2 = [s/2, sqrt(3)/2 * s, 0];
            v3 = [s/2, sqrt(3)/6 * s, sqrt(6)/3 * s];
            
            // Tetrahedron center
            center = [(v0[0]+v1[0]+v2[0]+v3[0])/4, (v0[1]+v1[1]+v2[1]+v3[1])/4, (v0[2]+v1[2]+v2[2]+v3[2])/4];
            
            // Face 1: front face (vertices v0, v1, v3)
            face1_center = [(v0[0] + v1[0] + v3[0])/3, (v0[1] + v1[1] + v3[1])/3, (v0[2] + v1[2] + v3[2])/3];
            face1_normal = face_normal(v0, v1, v3, center);
            face1_rotation = vector_to_euler(face1_normal);
            
            translate(0.5 * face1_center)
            rotate(face1_rotation)
            fractal_tetra(next_size, depth - 1);
            
            // Face 2: right face (vertices v1, v2, v3)  
            face2_center = [(v1[0] + v2[0] + v3[0])/3, (v1[1] + v2[1] + v3[1])/3, (v1[2] + v2[2] + v3[2])/3];
            face2_normal = face_normal(v1, v2, v3, center);
            face2_rotation = vector_to_euler(face2_normal);
            
            translate(1.0 * face2_center)
            rotate(face2_rotation)
            fractal_tetra(next_size, depth - 1);
            
            // Face 3: left face (vertices v2, v0, v3)
            face3_center = [(v2[0] + v0[0] + v3[0])/3, (v2[1] + v0[1] + v3[1])/3, (v2[2] + v0[2] + v3[2])/3];
            face3_normal = face_normal(v2, v0, v3, center);
            face3_rotation = vector_to_euler(face3_normal);
            
            translate(0.5 * face3_center)
            rotate(face3_rotation)
            fractal_tetra(next_size, depth - 1);
        }
    }
}

// Simpler approach using known tetrahedron geometry
module fractal_tetra_simple(s, depth) {
    if (s >= nozzle_width && depth > 0) {
        tetra(s);
        
        next_size = s * scale_factor;
        if (next_size >= nozzle_width && depth > 1) {
            // For a regular tetrahedron, we can use known angles
            // The angle between adjacent faces is about 70.5 degrees
            
            // Face centers at 2/3 height for the three upper faces
            h = sqrt(6)/3 * s;  // tetrahedron height
            face_height = h * 2/3;
            
            // Front face 
            rotate([70.53, 0, 0])  // this is arccos(1/3) ~ 70.53deg
            translate([1/3, sqrt(3)/12 , 2*sqrt(6)/9 ] * s * 0.0)
            translate([0, 0, next_size * sqrt(6)/12] * 0.0)
            fractal_tetra_simple(next_size, depth - 1);
            
            // Right face
            rotate([2*(90-70.53), 0, 60]) // twice the angle between the face and 90deg
            translate([3/4, 5*sqrt(3)/12, sqrt(6)/3 * 2/3] * s * 0.0)
            translate([0, 0, next_size * sqrt(6)/12] * 0.0)
            fractal_tetra_simple(next_size, depth - 1);
            
            // Left face
            //rotate([0,0,180])
            translate([30,0,0])
            rotate([0, 0, 60])
            rotate([-22,-35,5])
            translate([s/4, 5*sqrt(3)/12 * s, face_height] * 0.0)
            translate([0, 0, next_size * sqrt(6)/12] * 0.0)
            fractal_tetra_simple(next_size, depth - 1);
        }
    }
}

// Main call - try the simple version first
fractal_tetra_simple(size, recursion_depth);

// Uncomment to try the calculated version instead:
// fractal_tetra(size, recursion_depth);

echo("Tetrahedral Fractal Parameters:");
echo(str("Base Size: ", size));
echo(str("Scale Factor: ", scale_factor));  
echo(str("Recursion Depth: ", recursion_depth));