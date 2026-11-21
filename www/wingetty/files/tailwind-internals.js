// Stand-ins for the Tailwind CSS internals that tailwind-scrollbar requires. The standalone
// Tailwind CLI bundles its own copy of Tailwind and resolves only its public modules for plugins.

function flattenColorPalette(colors) {
  return Object.assign(
    {},
    ...Object.entries(colors ?? {}).flatMap(([color, values]) =>
      typeof values == 'object'
        ? Object.entries(flattenColorPalette(values)).map(([number, hex]) => ({
            [color + (number === 'DEFAULT' ? '' : `-${number}`)]: hex,
          }))
        : [{ [`${color}`]: values }],
    ),
  );
}

function toColorValue(maybeFunction) {
  return typeof maybeFunction === 'function' ? maybeFunction({}) : maybeFunction;
}

function flagEnabled(config, flag) {
  const future = config.future;
  return (
    future === 'all' || (future != null && typeof future === 'object' && future[flag] === true)
  );
}

module.exports = { flattenColorPalette, toColorValue, flagEnabled };
