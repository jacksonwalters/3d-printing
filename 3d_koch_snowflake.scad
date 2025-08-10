// =====================================
// Nozzle-Aware Tetrahedral Fractal
// =====================================

// Parameters
size = 30;            // base tetrahedron edge length (mm)
nozzle_width = 0.4;   // printer nozzle diameter (mm)
scale_factor = 0.5;   // size reduction per recursion step

// --- Base tetrahedron ---
module tetra(s) {
    hull() {
        for (i = [
            [0, 0, 0],
            [s, 0, 0],
            [s/2, sqrt(3)/2 * s, 0],
            [s/2, sqrt(3)/6 * s, sqrt(6)/3 * s]
        ]) {
            translate(i) sphere(0.01); // vertices; hull makes faces
        }
    }
}

// --- Recursive fractal builder ---
module fractal_tetra(s) {
    if (s >= nozzle_width) {
        tetra(s);
        next_size = s * scale_factor;
        if (next_size >= nozzle_width) {
            // Positions for sub-tetrahedra (relative to parent)
            positions = [
                [0, 0, 0],
                [s, 0, 0],
                [s/2, sqrt(3)/2 * s, 0],
                [s/2, sqrt(3)/6 * s, sqrt(6)/3 * s]
            ];
            for (pos = positions) {
                translate(pos)
                    fractal_tetra(next_size);
            }
        }
    }
}

// --- Main call ---
fractal_tetra(size);
