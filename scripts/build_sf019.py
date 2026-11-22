#!/usr/bin/env python3
"""Compile app and existing isolated SF-019/SF-021 test host with installed tools; never publish or install."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--analyzers', action='store_true', help='Run the installed CodeCop and UICop on the main app with warnings as errors.')
    parser.add_argument('--dotnet', type=Path)
    parser.add_argument('--compiler', type=Path)
    args = parser.parse_args()
    compilers = sorted((Path.home() / '.vscode/extensions').glob('ms-dynamics-smb.al-*/bin/alc.dll'))
    runtimes = sorted((Path.home() / 'Library/Application Support/Code/User/globalStorage/ms-dotnettools.vscode-dotnet-runtime/.dotnet').glob('10.*~arm64~aspnetcore/dotnet'))
    compiler = args.compiler or (compilers[-1] if compilers else None)
    dotnet = args.dotnet or (runtimes[-1] if runtimes else None)
    if compiler is None or dotnet is None:
        parser.error('Pass --compiler and --dotnet for an existing AL compiler and matching .NET host; no tools are installed.')
    subprocess.run([sys.executable, str(ROOT / 'scripts/check_inventory_contracts.py')], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'scripts/check_sales_contracts.py')], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'scripts/check_purchase_contracts.py')], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'scripts/check_template_contracts.py')], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'scripts/check_config_export_contracts.py')], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(ROOT / 'scripts/check_modular_contracts.py')], cwd=ROOT, check=True)
    output = (args.output or Path(tempfile.mkdtemp(prefix='bcsf-sf019-build-'))).resolve()
    output.mkdir(parents=True, exist_ok=True)
    app = output / 'app'
    tests = output / 'tests'
    cache = output / 'symbols'
    for target in (app, tests, cache):
        target.mkdir(exist_ok=True)
    for folder in ('src', 'Translations'):
        shutil.copytree(ROOT / folder, app / folder, dirs_exist_ok=True)
    shutil.copy2(ROOT / 'app.json', app / 'app.json')
    shutil.copytree(ROOT / 'tests/SF019', tests, dirs_exist_ok=True)
    for symbol in (ROOT / '.alpackages').glob('*.app'):
        shutil.copy2(symbol, cache / symbol.name)

    def compile_project(project, filename, extra=()):
        command = [str(dotnet), str(compiler), '/project:' + str(project),
                   '/packagecachepath:' + str(cache), '/out:' + str(output / filename),
                   '/target:Cloud', '/generatecode+', *extra]
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        (output / (filename + '.log')).write_text(result.stdout)
        print(result.stdout)
        if result.returncode:
            raise SystemExit(result.returncode)

    analysis = ()
    if args.analyzers:
        analysis = ('/warnaserror+', '/analyzer:' + ','.join(str(compiler.parent / name) for name in ('Microsoft.Dynamics.Nav.CodeCop.dll', 'Microsoft.Dynamics.Nav.UICop.dll')))
    compile_project(app, 'BCScenarioFactory.app', analysis)
    shutil.copy2(output / 'BCScenarioFactory.app', cache / 'BCScenarioFactory.app')
    compile_project(tests, 'BCScenarioFactory-SF019-Tests.app', ('/define:BCSFTESTS',))
    print('Compiled app and separate test app:', output)
    print('No Business Central tests were run; no package was published or installed.')


if __name__ == '__main__':
    main()
