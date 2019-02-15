const child_process = require('child_process');
const http = require('http');

const config = require('pelias-config').generate();
const logger = require('pelias-logger').get('schema');
const es = require('elasticsearch');

const cli = require('./cli');
const schema = require('../schema');

const client = new es.Client(config.esclient);

// check mandatory plugins are installed before continuing
try {
  child_process.execSync( 'node ' + __dirname + '/check_plugins.js' );
} catch( e ){
  console.error( "please install mandatory plugins before continuing.\n");
  process.exit(1);
}

if (http.maxHeaderSize === undefined) {
  logger.warn('You are using a version of Node.js that does not support the --max-http-header-size option.' +
    'You may experience issues when using Elasticsearch 5.' +
    'See https://github.com/pelias/schema#compatibility for more details.');
}

if (http.maxHeaderSize < 16384) {
  logger.error('Max header size is below 16384 bytes. ' +
    'Be sure to use the provided wrapper script in \'./bin\' rather than calling this script directly.' +
    'Otherwise, you may experience issues when using Elasticsearch 5.' +
    'See https://github.com/pelias/schema#compatibility for more details.');
  process.exit(1);
}

const aliasName = process.argv[2];
const indexName = config.schema.indexName;

cli.header("create (or update) alias");

(async function (){
  let indexNames = await client.cat.indices({h:"index"})
  indexNames = indexNames.trim().split("\n");

  if(!indexName in indexNames) {
    console.error(`Index ${indexName} does not exist. Create with 'pelias elastic create'`); 
    exit(1);
  }

  try {
    const aliasExistsArray = await Promise.all(indexNames.map(
      index => client.indices.existsAlias({index: index, name: aliasName})
    ));
    const [aliasedIndex] = indexNames.filter((i, idx) => aliasExistsArray[idx])
    let actions = [
      { add: {index: indexName, alias: aliasName}}
    ];

    if (!!aliasedIndex) {
      console.log(`Repointing alias ${aliasName} from ${aliasedIndex} to ${indexName}`);
      actions.push({remove: {index: aliasedIndex, alias: aliasName}});
    } else {
      console.log(`Creating alias ${aliasName}, pointing to ${indexName}`);
    }

    const {acknowledged: acked} = await client.indices.updateAliases({ body: { actions }})
    if(acked) {
      console.log(`Successfully pointed alias ${aliasName} at index ${indexName}`);
      process.exit(acked);
    }
  } catch (err) {
    console.error( err.message || err, '\n');
  } finally {
    console.err(`Unable to create/update alias ${aliasName}`);
  }
  process.exit(1);
})();

