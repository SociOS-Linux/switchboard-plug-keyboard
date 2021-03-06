/*
* 2019-2020 elementary, Inc. (https://elementary.io)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

public class Pantheon.Keyboard.InputMethodPage.AddEnginesPopover : Gtk.Popover {
    public signal void add_engine (string new_engine);

#if IBUS_1_5_19
    private List<IBus.EngineDesc> engines;
#else
    private List<weak IBus.EngineDesc> engines;
#endif

    private Gtk.SearchEntry search_entry;
    private GLib.ListStore liststore;
    private Gtk.ListBox listbox;

    construct {
        search_entry = new Gtk.SearchEntry () {
            margin = 12
        };

        ///TRANSLATORS: This text appears in a search entry and tell users to type some search word
        ///to look for a input method engine they want to add.
        ///It does not mean search engines in web browsers.
        search_entry.placeholder_text = _("Search engine");

        liststore = new GLib.ListStore (Type.OBJECT);

        listbox = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            expand = true,
            height_request = 300,
            width_request = 500
        };
        scrolled.add (listbox);

        var install_button = new Gtk.Button.with_label (_("Install Unlisted Engines…"));

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var add_button = new Gtk.Button.with_label (_("Add Engine"));
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.END,
            margin = 12,
            spacing = 6
        };
        button_box.add (install_button);
        button_box.add (cancel_button);
        button_box.add (add_button);
        button_box.set_child_secondary (install_button, true);

        var grid = new Gtk.Grid ();
        grid.attach (search_entry, 0, 0);
        grid.attach (scrolled, 0, 1);
        grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 2);
        grid.attach (button_box, 0, 3);

        add (grid);

        listbox.button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
                trigger_add_engine ();
                return false;
            }

            return false;
        });

        listbox.set_filter_func ((list_box_row) => {
            var item = (AddEnginesList) liststore.get_item (list_box_row.get_index ());
            return search_entry.text.down () in item.engine_full_name.down ();
        });

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });

        install_button.clicked.connect (() => {
            popdown ();

            var install_dialog = new InstallEngineDialog ((Gtk.Window) get_toplevel ());
            install_dialog.run ();
            install_dialog.destroy ();
        });

        cancel_button.clicked.connect (() => {
            popdown ();
        });

        add_button.clicked.connect (() => {
            trigger_add_engine ();
        });
    }

    private void trigger_add_engine () {
        int index = listbox.get_selected_row ().get_index ();

        // If the engine trying to add is already active, do not add it
        foreach (var active_engine in Utils.active_engines) {
            if (active_engine == (((AddEnginesList) liststore.get_item (index)).engine_id)) {
                popdown ();
                return;
            }
        }

        add_engine (((AddEnginesList) liststore.get_item (index)).engine_id);
    }

    public void update_engines_list () {
        engines = new IBus.Bus ().list_engines ();
        liststore.remove_all ();

        foreach (var engine in engines) {
            liststore.append (new AddEnginesList (engine));
        }

        liststore.sort ((a, b) => {
            return ((AddEnginesList) a).engine_full_name.collate (((AddEnginesList) b).engine_full_name);
        });

        for (int i = 0; i < liststore.get_n_items (); i++) {
            var label = new Gtk.Label (((AddEnginesList) liststore.get_item (i)).engine_full_name) {
                halign = Gtk.Align.START,
                margin = 6,
                margin_end = 12,
                margin_start = 12
            };

            var listboxrow = new Gtk.ListBoxRow ();
            listboxrow.add (label);

            listbox.add (listboxrow);
        }

        listbox.select_row (listbox.get_row_at_index (0));
        search_entry.grab_focus ();
    }
}
