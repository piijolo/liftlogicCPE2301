# liftlogicCPE2301
CPE2301 ramamoorthy liftlogic final project
LiftLogic/
├── src/
│   ├── liftlogic_top.sv
│   ├── inputlogic.sv       // Piolo
│   ├── elevator_fsm.sv           // Alejandro
│   ├── movement_timer.sv         // Thomas
│   ├── door_controller.sv        // Thomas
│   ├── emergency_controller.sv   // Thomas
│   ├── display_controller.sv     // Zwe
│   └── seven_seg_driver.sv       // Zwe
├── sim/
│   └── liftlogic_tb.sv
├── constraints/
│   └── basys3.xdc
└── README.md



Piolo: input_controller
        ↓ request pulses
Piolo: request_manager
        ↓ pending cabin / up / down requests
Alejandro: elevator_fsm
        ↓ movement, service, direction, door commands
Thomas: timer + door/emergency controller
        ↓ timer_done, emergency/hold status
Alejandro: elevator_fsm
        ↓ current floor, direction, door status, pending requests
Zwe: display_controller
