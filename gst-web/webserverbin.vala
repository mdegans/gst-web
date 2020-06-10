/* webserverbin.vala
 *
 * Copyright 2020 Michael de Gans <47511965+mdegans@users.noreply.github.com>
 *
 * 9F60E46EB32287EAFF84003A7002A439D55DC995401E91557710AFF3F65DE0E3
 * 627ED3694B0CCE117C2253BE66C83E904C140623B8DBE6D5C97BEFF335300DA8
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

public class ServerBin: Gst.Bin {
	// TODO(mdegans): see if there is a way to copy this from mpegtsmux directly
	//  but this is static so I kind of doubt it.
	// TODO(mdegans): prune stuff that isn't supported by HLS.
	/**
	 * The sink caps string. Copied directly from mpegtsmux.
	 */
	public const string SINK_CAPS_STR = """video/mpeg, 
mpegversion = (int) { 1, 2, 4 }, 
parsed = (boolean) TRUE, 
systemstream = (boolean) false; 
video/x-dirac; 
image/x-jpc; 
video/x-h264,stream-format=(string)byte-stream, 
alignment=(string){au, nal}; 
video/x-h265,stream-format=(string)byte-stream, 
alignment=(string){au, nal}; 
audio/mpeg, 
parsed = (boolean) TRUE, 
mpegversion = (int) { 1, 2 }; 
audio/mpeg, 
framed = (boolean) TRUE, 
mpegversion = (int) 4, stream-format = (string) adts; 
audio/mpeg, 
mpegversion = (int) 4, stream-format = (string) raw; 
audio/x-lpcm, 
width = (int) { 16, 20, 24 }, 
rate = (int) { 48000, 96000 }, 
channels = (int) [ 1, 8 ], 
dynamic_range = (int) [ 0, 255 ], 
emphasis = (boolean) { FALSE, TRUE }, 
mute = (boolean) { FALSE, TRUE }; 
audio/x-ac3, framed = (boolean) TRUE; 
audio/x-dts, framed = (boolean) TRUE; 
audio/x-opus, 
channels = (int) [1, 8], 
channel-mapping-family = (int) {0, 1}; 
subpicture/x-dvb; application/x-teletext; meta/x-klv, parsed=true; 
image/x-jpc, profile = (int)[0, 49151];""";

	// set static metadata and pad caps
	static construct {
		set_static_metadata(
			"Nginx Server Bin",
			"Sink/Network",
			"Sink bin with mpegtsmux, hlssink and an Nginx subprocess.",
			"Michael de Gans <michael.john.degans@gmail.com>");
		// so this took quite a bit of studying gstreamer macros
		// still not sure I have it 100%, but gst-inspect seems
		// to be ok with it
		Gst.StaticCaps sink_caps = {
			null, // so the trick is to put null here (GStreamer fills this out with the string)
// https://gstreamer.freedesktop.org/documentation/gstreamer/gstcaps.html?gi-language=c#GST_STATIC_CAPS
			SINK_CAPS_STR,
		};
		Gst.StaticPadTemplate sink_pad_template = {
			"sink_%d",
			Gst.PadDirection.SINK,
			Gst.PadPresence.REQUEST,
			sink_caps,
		};
		add_static_pad_template(sink_pad_template);
		// we have no SRC pad since this is a pure sink
	}

	/**
	 * Nginx Subprocess.
	 */
	protected Subprocess? server;
	/**
	 * the transport stream muxer.
	 */
	public Gst.Element mpegtsmux;
	/**
	 * The HLS sink (a kind of multifilesink).
	 */
	public Gst.Element hlssink;

	/* Properties:
	 */

	[Description(
		nick = "web temp path",
		blurb = "Temporary path used to serve file from.")]
	public string? web_tmp { get; default = null; }

	[Description(
		nick = "nginx executable",
		blurb = "The full path to an nginx binary.")]
	public string? nginx_exe {
		get;
		set;
		default = Environment.find_program_in_path("nginx");
	}

	[Description(
		nick = "nginx config template",
		blurb = "The full path to an nginx.config template.")]
	public string nginx_config { get; set; default = Gst.Web.DEFAULT_NGINX_CONF; }

	[Description(
		nick = "html title",
		blurb = "Contents of the html title tag.")]
	public string title { get; set; default = Gst.Web.DEFAULT_TITLE; }

	[Description(
		nick = "poster image",
		blurb = "Relative path (with web root) to poster image. Change only if you hate doggos.")]
	public string poster { get; set; default = Gst.Web.DEFAULT_POSTER; }

	[Description(
		nick = "web root source",
		blurb = "The web root to *copy* from (to /tmp/gst-web...).")]
	public string web_root_source { get; set; default = Gst.Web.DEFAULT_WEB_ROOT; }

	[Description(
		nick = "port",
		blurb = "Port to serve http on.")]
	public int port { get; set; default = Gst.Web.DEFAULT_PORT; }

	[Description(
		nick = "hostname",
		blurb = "Hostname to use (defaults to real hostname).")]
	public string hostname { get; set; default = Environment.get_host_name(); }

	[Description(
		nick = "public web uri",
		blurb = "The web root's publicly accessable uri.")]
	public string web_uri {
		owned get {
			return @"http://$(this.hostname):$(this.port)/";
		}
	}

	[Description(
		nick = "video root",
		blurb = "The active video root.")]
	public string? video_root {
		 owned get {
			 if (this.web_tmp == null) {
					// TODO(mdegans) test what happens if you give build_filename
					// null as a first parameter
					return null;
			 }
			 return Path.build_filename(this.web_tmp, Gst.Web.VIDEO_SUBDIR);
		 }
	}

	// constructor
	public ServerBin(string? name=null) {
		if (name != null){
			this.name = name;
		}
		this.server = null;

		// create and add our elements, posting messages on failure
		this.mpegtsmux = mad(this, "mpegtsmux", "mpegtsmux");
		this.hlssink = mad(this, "hlssink", "hlssink");
		if (mpegtsmux == null | this.hlssink == null) {
			return;
		}

		// try to link
		if (!this.mpegtsmux.link(hlssink)) {
			var err = new Gst.CoreError.FAILED(
				@"$(this.name) failed to link mpegtsmux and hlssink");
			message_full_failed(this, err, "link fail");
			return;
		}
	}

	/**
	 * Start or restart nginx in a subprocess.
	 *
	 * @param flags Any desired SubprocessFlags
	 */
	public virtual void restart(SubprocessFlags flags=SubprocessFlags.STDOUT_SILENCE) {
		if (this.server == null) {
			// if the server is null, start one
			string[] command = {this.nginx_exe, "-c", this.nginx_config, null};
			// this is similar to the Python subprocess.Popen
			try {
				this.server = new Subprocess.newv(command, flags);
			} catch (Error err) {
				// forward error message to the bus
				message_full_failed(this, err, "failed to start nginx");
			}
		} else {
			// graceful quit
			this.server.send_signal(Posix.Signal.QUIT);
			// register a callback when it's finished to .restart with the same flags
			this.server.wait_check_async.begin(null, (_, async_result) => {
				try {
					// get the async result of the operation
					bool success = this.server.wait_check_async.end(async_result);
					// if the quit was sucessful
					if (success) {
						// restart the server
						this.server = null;
						this.restart(flags);
					} else {
						// post a FAILED message on the bus
						var err = new Gst.CoreError.FAILED(
							@"nginx terminated abnormally. check it's log.");
						message_full_failed(this, err, "nginx abnormal termination");
					}
				} catch (Error err) {
					// post a FAILED message on the bus
					message_full_failed(this, err, "nginx failed to restart");
				}
			});
		}
	}

	/**
	 * {@inheritDoc}
	 */
	public new virtual Gst.Pad? get_request_pad(string name) {
		// try to get the real request pad
		var inner_sink = this.mpegtsmux.get_request_pad(name);
		if (inner_sink == null) {
			return null;
		}
		// try to get the sink template from the inner pad
		var inner_sink_template = inner_sink.get_pad_template();
		if (inner_sink_template == null) {
			return null;
		}
		// ghost the inner pad to the outer pad
		var outer_sink = new Gst.GhostPad.from_template(
			inner_sink.name, inner_sink, inner_sink_template);
		// add the ghosted pad to the outside of the bin
		this.add_pad(outer_sink);
		// return the ghosted pad
		return outer_sink;
	}

	/**
	 * {@inheritDoc}
	 */
	public new virtual void release_request_pad(Gst.Pad pad) {
		// cast to a ghost pad since we know
		// we're handing out ghost pads on request
		Gst.GhostPad ghost_pad = (Gst.GhostPad) pad;
		// gstreamer docs:
		// Pads are not automatically deactivated so elements 
		// should perform the needed steps to deactivate the 
		// pad in case this pad is removed in the PAUSED or 
		// PLAYING state. See gst_pad_set_active() for more
		// information about deactivating pads.
		Gst.State current;
		Gst.State pending;
		// FIXME(mdegans): this needs to be more rubust
		Gst.StateChangeReturn ret = this.get_state(out current, out pending, 0);
		// FIXME(mdegans): handle ASYNC here
		if (ret == Gst.StateChangeReturn.FAILURE) {
			var err = new Gst.CoreError.STATE_CHANGE(
				@"$(this.name) failed change state from $(current.to_string()) to $(pending.to_string()) ($(ret.to_string()))");
			message_full_failed(this, err, "pad remove fail");
			return;
		}
		// get the real pad the ghost proxies
		var inner_pad = ghost_pad.get_target();
		// remove the ghost pad, unreferencing (and destroying) it
		if (!this.remove_pad(ghost_pad)) {
			var err = new Gst.CoreError.PAD(
				@"failed to remove $(ghost_pad.name) from $(this.name)");
			message_full_failed(this, err, "pad remove fail");
			return;
		}
		// do likewise for the real inner pad
		if (!this.mpegtsmux.remove_pad(inner_pad)) {
			var err = new Gst.CoreError.PAD(
				@"failed to remove $(inner_pad.name) from $(this.mpegtsmux.name)");
			message_full_failed(this, err, "pad remove fail");
			return;
		}
	}

	/**
		* Reload nginx configuration (send SIGHUP).
		*
		* If the config file *path* has changed (with .nginx_config), use restart() instead.
		*/
	public virtual void reload_config() {
		if (this.server != null) {
			this.server.send_signal(Posix.Signal.HUP);
		}
	}

	/**
	 * Prep real web root by copying this.web_root to a new,
	 * unique, private, mode 700 folder under /tmp
	 */
	protected virtual void prep_web_root() throws Error {
		// create a tempdir if it doesn't exist
		this.cleanup_web_tmp();
		this._web_tmp = DirUtils.make_tmp("gst-web");
		// copy web root to the tmpdir
		var src = File.new_for_path(this.web_root_source);
		var dst = File.new_for_path(this.web_tmp);
		copy_recursive(src, dst);
	}

	/**
	 * Cleanup /tmp/gst-web...
	 */
	protected virtual void cleanup_web_tmp() throws Error {
		if (this.web_tmp == null) {
			return;
		}
		// sanity check (we're doing a rm -rf here), so let's make
		// sure web_tmp.startswith("/tmp")
		if (this.web_tmp.has_prefix(Environment.get_tmp_dir())) {
			// glib has no recursive delete, so we'll use Subprocess
			// TODO(mdegans): keep a set of files during copy_recursive
			// and just delete those as it's safer (but there are .ts
			// files and the plalist to consider too. this is where
			// python can be more concise.
			string[] command = {"rm", "-rf", this.web_tmp, null};
			try {
				var rm_process = new Subprocess.newv(
					command, SubprocessFlags.STDOUT_SILENCE);
				rm_process.wait_check_async.begin(null, (_, async_result) => {
					try {
						// get the async result of the operation
						bool success = this.server.wait_check_async.end(async_result);
						// if the rm, failed
						if (!success) {
							// post a FAILED message on the bus
							var err = new Gst.CoreError.FAILED(
								@"rm -rf of $(this.web_tmp) failed");
							message_full_failed(this, err, "cleanup fail");
						}
					} catch (Error err) {
						// post a FAILED message on the bus
						message_full_failed(this, err, "cleanup fail");
					}
				});
			} catch (Error err) {
				// forward error message to the bus
				message_full_failed(this, err, "cleanup fail");
			}
		}
	}
}

} // namespace Gst.Web