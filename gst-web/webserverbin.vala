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
	/**
	 * Nginx Subprocess
	 */
	protected Subprocess? server;

	// properties
	[Description(nick = "nginx executable", blurb = "The full path to an nginx binary.")]
	public string nginx_exe { get; set; default = "@nginx_path@"; }
	[Description(nick = "nginx config file", blurb = "The full path to an nginx config file.")]
	public string nginx_config { get; set; default = "@nginx_config@"; }

	// constructor
	public ServerBin(string? name=null) {
		if (name != null){
			this.name = name;
		}
		this.server = null;
	}

	/**
	 * Start or restart nginx in a subprocess.
	 * 
	 * @param flags Any desired SubprocessFlags
	 */
	public virtual void restart(SubprocessFlags flags=SubprocessFlags.STDOUT_SILENCE) throws Error {
		if (this.server == null) {
			// if the server is null, start one
			string[] command = {this.nginx_exe, "-c", this.nginx_config, null};
			// this is similar to the Python subprocess.Popen
			this.server = new Subprocess.newv(command, flags);
		} else {
			// graceful quit
			this.server.send_signal(Posix.Signal.QUIT);
			// register a callback when it's finished to .restart with the same flags
			this.server.wait_check_async.begin(null, (_, async_result) => {
				try {
					bool success = this.server.wait_check_async.end(async_result);
					if (success) {
						this.server.send_signal(Posix.Signal.TERM);
						this.server = null;
						this.restart(flags);
					} else {
						warning(@"nginx terminated abnormally. check it's log.");
					}
				} catch (Error err) {
					warning(err.message);
				}
			});
		} 
	}

	/**
	 * Reload nginx configuration (send SIGHUP).
	 * 
	 * If the config file *path* has changed (with .nginx_config), use restart() instead.
	 */
	public virtual void reload() {
		if (this.server != null) {
			this.server.send_signal(Posix.Signal.HUP);
		}
	}
}

} // namespace Gst.Web