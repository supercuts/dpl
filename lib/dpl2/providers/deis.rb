module Dpl
  module Providers
    class Deis < Provider
      summary 'Deis deployment provider'

      description <<~str
        tbd
      str

      opt '--controller NAME', 'Deis controller', required: true, example: 'deis.deisapps.com'
      opt '--username USER',   'Deis username', required: true
      opt '--password PASS',   'Deis password', required: true
      opt '--app APP',         'Deis app', required: true
      opt '--cli_version VER', 'Install a specific deis cli version', default: 'stable'
      opt '--verbose',         'Verbose log output'

      INSTALL = 'https://raw.githubusercontent.com/teamhephy/workflow-cli/master/install-v2.sh'

      CMDS = {
        add_key:    './deis keys:add %s',
        login:      './deis login %{controller} --username=%{username} --password=%{password}',
        info:       './deis apps:info --app=%{app}',
        deploy:     "bash -c 'git push %{verbose} %{url} HEAD:refs/heads/master -f 2>&1 | tr -dc \"[:alnum:][:space:][:punct:]\" | sed -E \"s/remote: (\\[1G)+//\" | sed \"s/\\[K$//\"; exit ${PIPESTATUS[0]}'",
        run:        './deis run -a %s -- %s',
        remove_key: './deis keys:remove %{key_name}'
      }

      ASSERT = {
        add_key:    'Adding keys failed.',
        login:      'Login failed.',
        info:       'Application could not be verified.',
        deploy:     'Deploying application failed.',
        run:        'Running command failed.',
        remove_key: 'Removing keys failed.'
      }

      needs_key
      keep 'deis'

      def install
        shell "curl -sSL #{INSTALL} | bash -x -s #{cli_version}"
      end

      def setup_key(file)
        shell :add_key, file, assert: true
        wait_for_ssh_access(host, port)
      end

      def check_auth
        shell :login, assert: true
      end

      def check_app
        shell :info, assert: true
      end

      def deploy
        shell :deploy, assert: true
      end

      def run_cmd(cmd)
        shell :run, cmd, app, echo: true, assert: true
      end

      def remove_key
        shell :remove_key, assert: true
      end

      def verbose
        verbose? ? '-v' : ''
      end

      def host
        url.host
      end

      def port
        url.port
      end

      def url
        @url ||= URI.parse("ssh://git@#{builder}:2222/#{app}.git")
      end

      def builder
        parts = controller_host.split('.')
        parts[0] = [parts[0], 'builder'].join('-')
        parts.join('.')
      end

      def controller_host
        controller.gsub(/https?:\/\//, '').split(':')[0].to_s
      end
    end
  end
end