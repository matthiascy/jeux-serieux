// script: js

var x = 70;
var y = 25;
var btn_label = ["Up", "Down", "Left", "Right", "Btn A", "Btn B"];

function TIC() {
    cls(0);
    print("Key Test Project", x, y);
    print("Btn", x, y + 15, 2);
    print("1P", x + 50, y + 15, 2);
    print("2P", x + 80, y + 15, 2);
    for (var i = 1; i <= 6; ++i) {
        print(btn_label[i],x,y+(i+1)*10+5);

        if (btn(i-1))
            print("On",x+50,y+(i+1)*10+5,11);
        else
            print("Off",x+47,y+(i+1)*10+5,6);

        if (btn(i+7))
            print("On",x+80,y+(i+1)*10+5,11);
        else
            print("Off",x+77,y+(i+1)*10+5,6);
    }
}
