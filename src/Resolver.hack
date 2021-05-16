namespace Slack\GraphQL;

use namespace Slack\GraphQL;
use namespace HH\Lib\{C, Vec};

final class Resolver {

    /**
     * @see https://spec.graphql.org/draft/#sec-Response
     */
    const type TResponse = shape(
        ?'data' => ?dict<string, mixed>, // missing data and null data are both valid states with different meanings
        ?'errors' => vec<UserFacingError::TError>, // errors are optional but cannot be null (or empty) if present
        ?'extensions' => dict<string, mixed>,
    );

    public function __construct(private classname<BaseSchema> $schema) {}

    /**
     * Operation name must be specified if the GraphQL request contains multiple operations.
     *
     * @see https://spec.graphql.org/draft/#sec-Execution
     */
    public async function resolve(
        string $input,
        dict<string, mixed> $variables = dict[],
        ?string $operation_name = null,
    ): Awaitable<this::TResponse> {
        // TODO: catch these errors
        $source = new \Graphpinator\Source\StringSource($input);
        $parser = new \Graphpinator\Parser\Parser($source);
        $request = $parser->parse();

        $ret = shape();
        $validator = new \Slack\GraphQL\Validation\Validator($this->schema);
        $errors = $validator->validate($request);

        if (C\is_empty($errors)) {
            try {
                list($ret['data'], $errors) = await $this->resolveImpl($request, $variables, $operation_name);
            } catch (UserFacingError $e) {
                $errors = vec[$e];
            } catch (\Throwable $e) {
                // TODO: This shoud not happen; if it does, it's a bug in the GraphQL framework. Every exception should
                // either be UserFacingError, or caught somewhere. However, we probably still want to catch arbitrary
                // exceptions here just in case and return *some* reasonable response.
                throw $e; // for now, so as to not break existing tests
            }
        }

        if (!C\is_empty($errors)) {
            $ret['errors'] = Vec\map($errors, $e ==> $e->toShape());
            return $ret;
        }
        return $ret;
    }

    public async function resolveImpl(
        \Graphpinator\Parser\ParsedRequest $request,
        dict<string, mixed> $raw_variables,
        ?string $operation_name,
    ): Awaitable<(?dict<string, mixed>, vec<UserFacingError>)> {
        $schema = $this->schema;

        if ($operation_name is nonnull) {
            GraphQL\assert(
                C\contains_key($request->getOperations(), $operation_name),
                'Operation %s not found in the request',
                $operation_name,
            );
            $operation = $request->getOperations()[$operation_name];
        } else {
            GraphQL\assert(
                C\count($request->getOperations()) === 1,
                'Operation name must be specified if the request contains multiple',
            );
            $operation = C\onlyx($request->getOperations());
        }

        $coerced_variables = $this->coerceVariables($operation->getVariables(), $raw_variables);

        $operation_type = $operation->getType();
        switch ($operation_type) {
            case 'query':
                $result = await $schema::resolveQuery($operation, $coerced_variables);
                break;
            case 'mutation':
                invariant($schema::MUTATION_TYPE, 'mutation operation not supported for schema');
                $result = await $schema::resolveMutation($operation, $coerced_variables);
                break;
            default:
                throw new \Error('Unsupported operation: '.$operation_type);
        }

        return tuple($result->getValue(), $result->getErrors());
    }

    private function coerceVariables(
        dict<string, \Graphpinator\Parser\Variable\Variable> $nodes,
        dict<string, mixed> $raw_values,
    ): dict<string, mixed> {
        $coerced_values = dict[];
        foreach ($nodes as $name => $node) {
            $type = Types\InputType::fromNode($this->schema, $node->getType());
            if (C\contains_key($raw_values, $name)) {
                try {
                    $coerced_values[$name] = $type->coerceValue($raw_values[$name]);
                } catch (UserFacingError $e) {
                    throw $e->prependMessage('Invalid value for variable "%s"', $name);
                }
                continue;
            }
            $default_node = $node->getDefault();
            if ($default_node is nonnull) {
                try {
                    $coerced_values[$name] = $type->coerceNode($default_node, dict[]);
                } catch (UserFacingError $e) {
                    throw $e->prependMessage('Invalid default value for variable "%s"', $name);
                }
                continue;
            }
            GraphQL\assert($type is Types\NullableInputType<_>, 'Missing value for required variable "%s"', $name);
        }
        return $coerced_values;
    }
}
