/* plugin.vala
 *
 * Copyright 2020 Michael de Gans <47511965+mdegans@users.noreply.github.com>
 * based off Vala boilerplate by Fabian Deutsch
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


// ignore any squigglies here. Meson will format this template
// with configure_file (see this folder's meson.build)
const Gst.PluginDesc gst_plugin_desc = {
	@gst_major_version@, @gst_minor_version@, 
	"@project_name@", 
	"@project_description@",
	plugin_init,
	"@version@",
	"@license@",
	"@project_url@",
	"@package_name@",
	"@origin@"
};

public static bool plugin_init(Gst.Plugin p) {
	Gst.Element.register(
		p,
		"webserverbin",
		Gst.Rank.NONE,
		typeof(Gst.Web.ServerBin)
	);
	return true;
}

// warning: Namespace Web does not have a GIR namespace and version annotation
// NOTE(mdegans): The above warning is because these attributes are omitted,
//  but if they are added, the naming in the header and gir ends up messed.
//
//  This is inconsistent with other package, but seems to make a prettier interface.
//
// documentation:
//
//  https://wiki.gnome.org/Projects/Vala/Manual/Attributes
//  ... and ... 
//  fgrep to the rescue!
//  ...
//  gstreamer-player-1.0.vapi:[CCode (cprefix = "Gst", gir_namespace = "GstPlayer", gir_version = "1.0", lower_case_cprefix = "gst_")]
//  gstreamer-riff-1.0.vapi:[CCode (cprefix = "Gst", gir_namespace = "GstRiff", gir_version = "1.0", lower_case_cprefix = "gst_")]
//  gstreamer-rtp-1.0.vapi:[CCode (cprefix = "Gst", gir_namespace = "GstRtp", gir_version = "1.0", lower_case_cprefix = "gst_")]
//  gstreamer-rtsp-1.0.vapi:[CCode (cprefix = "Gst", gir_namespace = "GstRtsp", gir_version = "1.0", lower_case_cprefix = "gst_")]
//  gstreamer-rtsp-server-1.0.vapi:[CCode (cprefix = "Gst", gir_namespace = "GstRtspServer", gir_version = "1.0", lower_case_cprefix = "gst_")]
//  ...
//  Uncomment, regenerate with ninja, and see what i mean in the gstweb.h and gstweb-@version@.gir
//  [CCode (cprefix = "Gst", gir_namespace = "GstWeb", gir_version = "@version@", lower_case_cprefix="gst_")]
namespace Gst.Web {

// plugin global constants
const string DEFAULT_NGINX_BIN = "@nginx_bin@";
const string DEFAULT_NGINX_CONF = "@nginx_conf@";

}