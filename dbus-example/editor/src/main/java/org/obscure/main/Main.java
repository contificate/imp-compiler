package org.obscure.main;

import com.formdev.flatlaf.FlatLightLaf;
import org.obscure.ui.MainWindow;

import javax.swing.*;

public class Main {
    public static void main(String[] args) {
        // aesthetics, yo
        FlatLightLaf.install();

        // queue primary view
        SwingUtilities.invokeLater(MainWindow::new);
    }
}
