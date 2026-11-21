package com.example.devlaunch;

import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import java.util.List;

class MyAdapter extends ArrayAdapter<String> {

    MyAdapter(Context context, List<String> objects) {
        super(context, android.R.layout.simple_list_item_1, objects);
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        TextView t = (TextView) super.getView(position, convertView, parent);
        t.setTextColor(0xFF4FC3F7);
        t.setTextSize(12);
        return t;
    }
}
