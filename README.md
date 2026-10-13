# Control de vidrio — OPERMAR SA

Primera versión de trabajo para el control operativo de cinco volquetas. Incluye acceso por usuario, posiciones de carga, asignación de operario, estados separados, declaración de rotura, verificaciones, diferencias resaltadas, egreso con dos remitos y un dashboard inicial del supervisor.

## Archivos
- `index.html`: aplicación web adaptable a celular y computadora.
- `schema.sql`: estructura de datos, catálogo de productos, cinco volquetas y políticas de seguridad RLS.
- `assets/volqueta-opermar.jpg`: fotografía de volqueta proporcionada por OPERMAR SA.
- `assets/logo-opermar-sa.png`: logo proporcionado por OPERMAR SA.

## Configuración inicial de Supabase
1. Abrí el proyecto `https://dhcwcfzsuekckmhgbkup.supabase.co`.
2. Entrá en **SQL Editor → New query**.
3. Copiá el contenido completo de `schema.sql` y ejecutalo.
4. En **Authentication → Users**, creá los usuarios de controladores y supervisor.
5. Copiá el UUID de cada usuario y ejecutá en SQL Editor, cambiando UUID, nombre y rol:
   ```sql
   insert into public.profiles(id, full_name, role)
   values ('UUID-DEL-USUARIO', 'Nombre Apellido', 'controller');
   ```
   Para el supervisor, el rol debe ser `supervisor`.
6. Agregá los operarios en la tabla `public.employees` desde **Table Editor**.
7. En las verificaciones, el controlador registra por posición la distribución de esqueletos como `botellas: cantidad`; por ejemplo `12:4,24:8` significa cuatro esqueletos de 12 botellas y ocho de 24. La aplicación calcula las botellas y los cajones equivalentes y resalta la diferencia.

## Publicar en GitHub Pages
1. Creá un repositorio separado, por ejemplo `control-vidrio-opermar`.
2. Subí `index.html`, `schema.sql`, `README.md` y la carpeta `assets` conservando la estructura.
3. En **Settings → Pages**, habilitá la publicación desde la rama principal y la carpeta raíz.
4. Abrí la URL que GitHub Pages te asigne.

## Importante antes de uso oficial
Esta es una primera versión funcional para probar el flujo. Probala con datos de ensayo antes de usarla como registro administrativo oficial. La habilitación de egreso se controla en la interfaz con el objetivo de rotura y la confirmación del retiro de esqueletos vacíos; antes de producción conviene reforzar la validación también del lado de la base de datos. La clave `sb_publishable_` es para el cliente web; nunca agregues una clave `service_role` ni secretos al HTML.
