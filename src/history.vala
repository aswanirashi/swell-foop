/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class History
{
    public string filename;
    public List<HistoryEntry> entries;

    public signal void entry_added (HistoryEntry entry);

    public History (string filename)
    {
        this.filename = filename;
        entries = new List<HistoryEntry> ();
    }

    public void add (HistoryEntry entry)
    {
        entries.append (entry);
        entry_added (entry);
    }

    public void load ()
    {
        entries = new List<HistoryEntry> ();

        var contents = "";
        try
        {
            FileUtils.get_contents (filename, out contents);
        }
        catch (FileError e)
        {
            if (!(e is FileError.NOENT))
                warning ("Failed to load history: %s", e.message);
            return;
        }

        foreach (var line in contents.split ("\n"))
        {
            var tokens = line.split (" ");
            if (tokens.length != 5)
                continue;

            var date = parse_date (tokens[0]);
            if (date == null)
                continue;
            var width = int.parse (tokens[1]);
            var height = int.parse (tokens[2]);
            var n_colors = int.parse (tokens[3]);
            var score = int.parse (tokens[4]);

            add (new HistoryEntry (date, width, height, n_colors, score));
        }
    }

    public void save ()
    {
        var contents = "";

        foreach (var entry in entries)
        {
            var line = "%s %u %u %u %u\n".printf (entry.date.to_string (), entry.width, entry.height, entry.n_colors, entry.score);
            contents += line;
        }

        try
        {
            DirUtils.create_with_parents (Path.get_dirname (filename), 0775);
            FileUtils.set_contents (filename, contents);
        }
        catch (FileError e)
        {
            warning ("Failed to save history: %s", e.message);
        }    
    }

    private DateTime? parse_date (string date)
    {
        if (date.length < 19 || date[4] != '-' || date[7] != '-' || date[10] != 'T' || date[13] != ':' || date[16] != ':')
            return null;

        var year = int.parse (date.substring (0, 4));
        var month = int.parse (date.substring (5, 2));
        var day = int.parse (date.substring (8, 2));
        var hour = int.parse (date.substring (11, 2));
        var minute = int.parse (date.substring (14, 2));
        var seconds = int.parse (date.substring (17, 2));
        var timezone = date.substring (19);

        return new DateTime (new TimeZone (timezone), year, month, day, hour, minute, seconds);
    }
}

public class HistoryEntry
{
    public DateTime date;
    public uint width;
    public uint height;
    public uint n_colors;
    public uint score;

    public HistoryEntry (DateTime date, uint width, uint height, uint n_colors, uint score)
    {
        this.date = date;
        this.width = width;
        this.height = height;
        this.n_colors = n_colors;
        this.score = score;
    }
}
