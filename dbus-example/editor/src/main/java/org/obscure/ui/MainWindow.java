package org.obscure.ui;

import javax.swing.*;

public class MainWindow extends JFrame {
    public MainWindow() {
        super("IMP Editor");
        setSize(600, 430);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        initComponents();
        setVisible(true);
    }

    private void initComponents() {
        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Program", new CodeEditor());
        add(tabs);
    }
}
