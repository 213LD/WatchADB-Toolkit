package com.example.devlaunch;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.provider.Settings;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.View;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class LaunchActivity extends Activity
        implements View.OnClickListener, AdapterView.OnItemClickListener, TextWatcher {

    private static final String[] QUICK = {
        "com.android.settings.DwDevelopSetActivity",
        "com.android.settings.Settings$DevelopmentSettingsActivity",
        "com.android.settings.DevelopmentSettings",
    };

    private MyAdapter adapter;
    private final List<String> allNames = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(24, 32, 24, 16);
        root.setBackgroundColor(Color.rgb(0x0E, 0x12, 0x16));

        TextView title = new TextView(this);
        title.setText("设置页探索器");
        title.setTextSize(15);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setTextColor(Color.WHITE);
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        Button dev = new Button(this);
        dev.setText("① 一键打开开发者选项");
        dev.setTextSize(13);
        dev.setOnClickListener(this);
        LinearLayout.LayoutParams bp = new LinearLayout.LayoutParams(-1, -2);
        bp.topMargin = 8;
        dev.setLayoutParams(bp);
        root.addView(dev);

        EditText filter = new EditText(this);
        filter.setHint("筛选: develop/factory/dw/eng");
        filter.setTextColor(Color.WHITE);
        filter.setHintTextColor(0xFF888888);
        filter.setTextSize(13);
        LinearLayout.LayoutParams fp = new LinearLayout.LayoutParams(-1, -2);
        fp.topMargin = 10;
        filter.setLayoutParams(fp);
        filter.addTextChangedListener(this);
        root.addView(filter);

        ListView lv = new ListView(this);
        adapter = new MyAdapter(this, new ArrayList<String>());
        lv.setAdapter(adapter);
        lv.setOnItemClickListener(this);
        root.addView(lv, new LinearLayout.LayoutParams(-1, -1, 1f));

        setContentView(root);
        load();
    }

    private void load() {
        PackageManager pm = getPackageManager();
        try {
            PackageInfo pi = pm.getPackageInfo("com.android.settings", PackageManager.GET_ACTIVITIES);
            if (pi.activities != null) {
                for (ActivityInfo ai : pi.activities) allNames.add(ai.name);
            }
        } catch (Exception ignored) {
        }
        if (allNames.isEmpty()) {
            List<PackageInfo> packs = pm.getInstalledPackages(0);
            for (PackageInfo p : packs) {
                if (p.packageName.contains("settings")) allNames.add("[包] " + p.packageName);
            }
        }
        Collections.sort(allNames);
        adapter.addAll(allNames);
        adapter.notifyDataSetChanged();
        if (allNames.isEmpty()) toast("没找到任何设置页面");
    }

    @Override
    public void onClick(View v) {
        for (String cls : QUICK) {
            if (tryStart(cls)) {
                finish();
                return;
            }
        }
        if (tryStartAction(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                || tryStart("com.android.settings.Settings")) {
            finish();
            return;
        }
        toast("已知入口全被拦，请用下方列表逐个尝试");
    }

    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        String cls = adapter.getItem(position);
        if (cls == null) {
            return;
        }
        if (cls.startsWith("[包] ")) {
            toast(cls + " 不是可打开的页面");
            return;
        }
        if (!tryStart(cls)) toast("打不开: " + cls);
    }

    @Override
    public void beforeTextChanged(CharSequence s, int a, int b, int c) {
    }

    @Override
    public void onTextChanged(CharSequence s, int a, int b, int c) {
    }

    @Override
    public void afterTextChanged(Editable s) {
        adapter.getFilter().filter(s.toString());
    }

    private boolean tryStart(String cls) {
        try {
            Intent i = new Intent();
            i.setClassName("com.android.settings", cls);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(i);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private boolean tryStartAction(String action) {
        try {
            Intent i = new Intent(action);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(i);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show();
    }
}
