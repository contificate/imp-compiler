package org.obscure.ui;

import org.fife.ui.rsyntaxtextarea.RSyntaxTextArea;
import org.fife.ui.rtextarea.RTextScrollPane;
import org.freedesktop.dbus.connections.impl.DBusConnection;
import org.freedesktop.dbus.exceptions.DBusException;
import org.imp.Compiler;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;

public class CodeEditor extends JPanel {
    private RSyntaxTextArea sourceArea = new RSyntaxTextArea();
    private JTextArea parsed = new JTextArea();
    private JTextArea compiled = new JTextArea();

    private Compiler compiler;

    private class ParseAction extends AbstractAction {
        public ParseAction() {
            super("Parse");
        }

        @Override
        public void actionPerformed(ActionEvent e) {
            parseResponse(compiler.ParseIMP(sourceArea.getText()), parsed);
        }
    }

    private class CompileAction extends AbstractAction {
        public CompileAction() {
            super("Compile");
        }

        @Override
        public void actionPerformed(ActionEvent e) {
            parseResponse(compiler.CompileIMP(sourceArea.getText()), compiled);
        }
    }

    private void parseResponse(final String response, final JTextArea target) {
        try {
            Object parsed = new JSONParser().parse(response);
            if (parsed instanceof JSONObject) {
                final JSONObject fields = (JSONObject) parsed;
                final Object status = fields.get("status");
                if (status instanceof Boolean && (Boolean) status)
                    target.setText(fields.get("value").toString());
            }
        } catch (ParseException ex) {
            JOptionPane.showMessageDialog(null, "Failed to parse DBus response!");
        }

    }


    public CodeEditor() {
        super(new BorderLayout());
        initCompiler();
        initComponents();
    }

    private void initCompiler() {
        try {
            DBusConnection conn = DBusConnection.getConnection(DBusConnection.DBusBusType.SESSION);
            compiler = conn.getRemoteObject("imp.compiler", "/Compiler", Compiler.class);
        } catch (DBusException e) {
            e.printStackTrace();
        }
    }

    private void initComponents() {
        JToolBar toolBar = new JToolBar();
        toolBar.setLayout(new BoxLayout(toolBar, BoxLayout.X_AXIS));
        toolBar.add(new ParseAction());
        toolBar.add(new CompileAction());
        add(toolBar, BorderLayout.NORTH);

        JPanel parsedPane = new JPanel(new BorderLayout());
        parsedPane.add(new JScrollPane(parsed), BorderLayout.CENTER);
        parsedPane.setBorder(BorderFactory.createTitledBorder("Parsed"));

        JPanel compiledPane = new JPanel(new BorderLayout());
        compiledPane.add(new JScrollPane(compiled), BorderLayout.CENTER);
        compiledPane.setBorder(BorderFactory.createTitledBorder("Compiled"));

        sourceArea.setFont(new Font("monospaced", Font.PLAIN, 14));

        JSplitPane right = new JSplitPane(JSplitPane.VERTICAL_SPLIT, parsedPane, compiledPane);
        right.setResizeWeight(0.5);
        JSplitPane left = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, new RTextScrollPane(sourceArea), right);
        left.setResizeWeight(0.5);
        add(left, BorderLayout.CENTER);
    }
}
