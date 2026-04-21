import 'dart:io';

void main() async {
  print('\n=========================================================');
  print('🚀 Agente Interactivo para enviar repositorio a GitHub');
  print('=========================================================\n');

  // 1. Preguntar por el link del nuevo repositorio
  stdout.write('1. Ingresa el link del nuevo repositorio en GitHub:\n   (Ej: https://github.com/usuario/repo.git)\n> ');
  String? repoLink = stdin.readLineSync()?.trim();

  if (repoLink == null || repoLink.isEmpty) {
    print('\n❌ Error: El link del repositorio es obligatorio.');
    return;
  }

  // 2. Preguntar por el commit
  stdout.write('\n2. Ingresa el mensaje para el commit:\n> ');
  String? commitMessage = stdin.readLineSync()?.trim();

  if (commitMessage == null || commitMessage.isEmpty) {
    commitMessage = 'Primer commit';
    print('   -> Se usará el mensaje por defecto: "$commitMessage"');
  }

  // 3. Establecer la rama main por defecto o pedir nombre
  stdout.write('\n3. Ingresa el nombre de la rama (presiona Enter para usar "main" por defecto):\n> ');
  String? branch = stdin.readLineSync()?.trim();

  if (branch == null || branch.isEmpty) {
    branch = 'main';
    print('   -> Se usará la rama por defecto: "$branch"');
  }

  print('\n---------------------------------------------------------');
  print('📋 Resumen de la operación:');
  print('   Repositorio : $repoLink');
  print('   Commit      : "$commitMessage"');
  print('   Rama        : $branch');
  print('---------------------------------------------------------\n');

  stdout.write('¿Deseas proceder con estos datos? (S/n): ');
  String? confirm = stdin.readLineSync()?.trim().toLowerCase();
  
  if (confirm != 's' && confirm != '') {
    print('\n🚫 Operación cancelada por el usuario.');
    return;
  }

  print('\n⚙️ Ejecutando comandos...\n');

  try {
    // Comprobar si git está instalado
    await checkGitInstalled();

    // Inicializar git (por si no está inicializado)
    await runGitCommand(['init'], 'Inicializando git local...');

    // Agregar todos los archivos
    await runGitCommand(['add', '.'], 'Agregando archivos al área de preparación...');

    // Realizar el commit
    // Usamos runGitCommand personalizado para manejar el caso de que no haya nada que comitear
    print('> Creando commit...');
    var commitResult = await Process.run('git', ['commit', '-m', commitMessage]);
    if (commitResult.exitCode != 0 && !commitResult.stdout.toString().contains('nothing to commit') && !commitResult.stdout.toString().contains('nada para hacer commit')) {
      print('❌ Error al hacer commit:\n${commitResult.stderr}\n${commitResult.stdout}');
      throw Exception('Fallo al realizar git commit');
    } else {
      print('  ✅ Commit realizado (o sin cambios nuevos).');
    }

    // Renombrar/establecer la rama principal
    await runGitCommand(['branch', '-M', branch], 'Configurando rama "$branch"...');

    // Configurar o actualizar el remote origin
    var remoteResult = await Process.run('git', ['remote']);
    if (remoteResult.stdout.toString().contains('origin')) {
      await runGitCommand(['remote', 'set-url', 'origin', repoLink], 'Actualizando enlace remoto origin...');
    } else {
      await runGitCommand(['remote', 'add', 'origin', repoLink], 'Agregando enlace remoto origin...');
    }

    // Subir los cambios a GitHub
    print('> Subiendo repositorio a GitHub (esto puede tardar unos segundos)...');
    var pushResult = await Process.start('git', ['push', '-u', 'origin', branch]);
    
    // Mostrar la salida del push en tiempo real
    stdout.addStream(pushResult.stdout);
    stderr.addStream(pushResult.stderr);
    
    var exitCode = await pushResult.exitCode;
    if (exitCode != 0) {
      throw Exception('Fallo al subir los cambios a GitHub. Revisa tus credenciales o conexión.');
    }

    print('\n🎉 ¡Proceso completado con éxito! El repositorio se ha subido correctamente.');

  } catch (e) {
    print('\n❌ Ha ocurrido un error durante la ejecución:');
    print(e.toString());
  }
}

Future<void> checkGitInstalled() async {
  try {
    var result = await Process.run('git', ['--version']);
    if (result.exitCode != 0) {
      throw Exception();
    }
  } catch (e) {
    throw Exception('Parece que Git no está instalado o no está en el PATH del sistema.');
  }
}

Future<void> runGitCommand(List<String> args, String mensaje) async {
  print('> $mensaje');
  var result = await Process.run('git', args);
  if (result.exitCode != 0) {
    print('❌ Error ejecutando: git ${args.join(' ')}');
    print('Detalles:\n${result.stderr}\n${result.stdout}');
    throw Exception('Error en comando git');
  } else {
    print('  ✅ Completado.');
  }
}
