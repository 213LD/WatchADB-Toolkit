package com.example.pctest;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("ADB 安装成功\n\n来自电脑的测试 APK");
        tv.setTextSize(22);
        tv.setGravity(Gravity.CENTER);
        tv.setTextColor(Color.WHITE);
        setContentView(tv);
    }
}
