struct VertexInput {
    @location(0) position: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

@group(0) @binding(0)
var<uniform> time: f32;

@vertex
fn vs_main(input: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.clip_position = vec4<f32>(input.position, 0.0, 1.0);
    out.uv = input.position;
    return out;
}

fn ray(uv: vec2<f32>) -> vec3<f32> {
    let d = vec3<f32>(uv.x, uv.y, 1.0);
    return normalize(d);
}

fn sdf(p: vec3<f32>) -> f32 {
    let pCos = vec3<f32>(cos(p.x),cos(p.y),cos(p.z));
    return length(pCos) - 1.0; // unit sphere at origin
}

fn march(ro: vec3<f32>, rd: vec3<f32>) -> f32 {
    var t: f32 = 0.0;
    for(var i: i32 = 0; i < 100; i++) {
        let p = ro + rd * t;
        let d = sdf(p);
        if d < 0.001 {
            return t;
        }
        t += d;
        if t > 100.0 {
            break;
        }
    }
    return t;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let r = ray(in.uv);
    let ro = vec3<f32>(0.0, sin(time), -5.0);
    let k = march(ro, r);
    
    var col: f32;
    if k < 100.0 {
        col = (1.0 - k / 10.0);
    } else {
        col = 0.0;
    }
    
    return vec4<f32>(col, col, col, 1.0);
}
