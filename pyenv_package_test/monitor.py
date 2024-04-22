import yaml
import fire
from time import sleep
from subprocess import run

from pyenv_package_test import config


def start_monitor(entire_progress_path):
    
    while True:
        with open(entire_progress_path, 'r') as f:
            data = yaml.safe_load(f)

        if data['entire']['state'] == 'finished':
            if data['entire']['passed']:
                prefix = '(passed)'
            else:
                prefix = '(failed)'

            sbj = prefix + 'finish pyenv-package-test!!'
            bdy = yaml.dump(data)

            run([
                'powershell',
                'send-mailmessage',
                '-from', config.mail_from,
                '-to',config.mail_to,
                '-subject', f'"{sbj}"',
                '-body', f'"{bdy}"',
                '-encoding', '([System.Text.Encoding]::UTF8)',
                '-port', config.port,
                '-smtpserver', config.smtpserver,
            ])

            break

        sleep(1)


if __name__ == '__main__':
    fire.Fire(start_monitor)
