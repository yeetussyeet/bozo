import sceneRenderer from "../rc-render"

sceneRenderer(
    {
        Parts: [
            {
                cf: {
                    position: {x:0,y:0,z:0},
                    orientation: {x:0,y:0,z:0}
                },
                size: {x:5,y:5,z:5},
                color: {r:1,g:1,b:1}
            }
        ],
        Camera: {
            position: {x:0,y:10,z:-20},
            orientation: {x:0,y:0,z:0}
        }
    },
    "test.png"
)