/* utils.vala
 *
 * Copyright 2020 Michael de Gans <47511965+mdegans@users.noreply.github.com>
 *
 * 66E67F6ADF56899B2AA37EF8BF1F2B9DFBB1D82E66BD48C05D8A73074A7D2B75
 * EB8AA44E3ACF111885E4F84D27DC01BB3BD8B322A9E8D7287AD20A6F6CD5CB1F
 *
 * This file is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

namespace Gst.Web {

/**
 * Make and add (to {@link Gst.Bin})
 */
static Gst.Element? mad(Gst.Bin bin, string element_type, string element_name) {
  var elem = Gst.ElementFactory.make(element_type, element_name);
  if (elem == null) {
    // so, this is totally undocumented
    bin.message_full(
      Gst.MessageType.ERROR, Gst.CoreError.quark(), Gst.CoreError.FAILED,
      "failed to create element", @"could not create element $element_type",
      Log.FILE, Log.METHOD, Log.LINE
    );
  }
  if (!bin.add(elem)) {
    bin.message_full(
      Gst.MessageType.ERROR, Gst.CoreError.quark(), Gst.CoreError.FAILED,
      "failed to add element", @"could not add $(elem.name) to $(bin.name)",
      Log.FILE, Log.METHOD, Log.LINE
    );
  }
  return elem;
}

/**
 * Pass an error to the {@link Gst.Bus}.
 */
static void message_full_failed(Gst.Element source, Error err, string text) {
  source.message_full(Gst.MessageType.ERROR, Gst.CoreError.quark(), Gst.CoreError.FAILED,
    text, err.message, Log.FILE, Log.METHOD, Log.LINE
  );
}

/**
 * Recursively copy a directory.
 * 
 * https://stackoverflow.com/questions/16453739/how-do-i-recursively-copy-a-directory-using-vala
 */
public bool copy_recursive (GLib.File src, GLib.File dest, GLib.FileCopyFlags flags = GLib.FileCopyFlags.NONE, GLib.Cancellable? cancellable = null) throws GLib.Error {
  GLib.FileType src_type = src.query_file_type (GLib.FileQueryInfoFlags.NONE, cancellable);
  if ( src_type == GLib.FileType.DIRECTORY ) {
    dest.make_directory (cancellable);
    src.copy_attributes (dest, flags, cancellable);

    string src_path = src.get_path ();
    string dest_path = dest.get_path ();
    GLib.FileEnumerator enumerator = src.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, cancellable);
    for ( GLib.FileInfo? info = enumerator.next_file (cancellable) ; info != null ; info = enumerator.next_file (cancellable) ) {
      copy_recursive (
        GLib.File.new_for_path (GLib.Path.build_filename (src_path, info.get_name ())),
        GLib.File.new_for_path (GLib.Path.build_filename (dest_path, info.get_name ())),
        flags,
        cancellable);
    }
  } else if ( src_type == GLib.FileType.REGULAR ) {
    src.copy (dest, flags, cancellable);
  }

  return true;
}

}