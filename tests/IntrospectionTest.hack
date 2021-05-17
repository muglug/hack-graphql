use namespace Slack\GraphQL;

use namespace HH\Lib\C;
use function Facebook\FBExpect\expect;

final class IntrospectionTest extends PlaygroundTest {

    <<__Override>>
    public static function getTestCases(): this::TTestCases {
        return dict[
            'select the name of the query type' => tuple(
                '{
                    __schema {
                        queryType {
                            kind
                            name
                        }

                        mutationType {
                            kind
                            name
                        }
                    }

                    __type(name: "Query") {
                        kind
                        name
                    }
                }',
                dict[],
                dict[
                    '__schema' => dict[
                        'queryType' => dict[
                            'kind' => 'OBJECT',
                            'name' => 'Query',
                        ],
                        'mutationType' => dict[
                            'kind' => 'OBJECT',
                            'name' => 'Mutation',
                        ],
                    ],
                    '__type' => dict[
                        'kind' => 'OBJECT',
                        'name' => 'Query',
                    ],
                ],
            ),
            'validate field introspection' => tuple(
                '{
                    __type(name: "IntrospectionTestObject") {
                        name
                        fields {
                            name
                            type {
                                kind
                                name
                                ofType {
                                    kind
                                    name
                                    ofType {
                                        kind
                                        name
                                        ofType {
                                            kind
                                            name
                                        }
                                    }
                                }
                            }
                        }
                    }
                }',
                dict[],
                dict[
                    '__type' => dict[
                        'name' => 'IntrospectionTestObject',
                        'fields' => vec[
                            dict[
                                'name' => 'default_list_of_non_nullable_int',
                                'type' => dict[
                                    'kind' => 'LIST',
                                    'name' => null,
                                    'ofType' => dict[
                                        'kind' => 'NON_NULL',
                                        'name' => null,
                                        'ofType' => dict[
                                            'kind' => 'SCALAR',
                                            'name' => 'Int',
                                            'ofType' => null,
                                        ],
                                    ],
                                ],
                            ],
                            dict[
                                'name' => 'default_list_of_nullable_int',
                                'type' => dict[
                                    'kind' => 'LIST',
                                    'name' => null,
                                    'ofType' => dict[
                                        'kind' => 'SCALAR',
                                        'name' => 'Int',
                                        'ofType' => null,
                                    ],
                                ],
                            ],
                            dict[
                                'name' => 'default_nullable_string',
                                'type' => dict[
                                    'kind' => 'SCALAR',
                                    'name' => 'String',
                                    'ofType' => null,
                                ],
                            ],
                            dict[
                                'name' => 'non_null_int',
                                'type' => dict[
                                    'kind' => 'NON_NULL',
                                    'name' => null,
                                    'ofType' => dict[
                                        'kind' => 'SCALAR',
                                        'name' => 'Int',
                                        'ofType' => null,
                                    ],
                                ],
                            ],
                            dict[
                                'name' => 'non_null_list_of_non_null',
                                'type' => dict[
                                    'kind' => 'NON_NULL',
                                    'name' => null,
                                    'ofType' => dict[
                                        'kind' => 'LIST',
                                        'name' => null,
                                        'ofType' => dict[
                                            'kind' => 'NON_NULL',
                                            'name' => null,
                                            'ofType' => dict[
                                                'kind' => 'SCALAR',
                                                'name' => 'Int',
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                            dict[
                                'name' => 'non_null_string',
                                'type' => dict[
                                    'kind' => 'NON_NULL',
                                    'name' => null,
                                    'ofType' => dict[
                                        'kind' => 'SCALAR',
                                        'name' => 'String',
                                        'ofType' => null,
                                    ],
                                ],
                            ],
                            dict[
                                'name' => 'nullable_string',
                                'type' => dict[
                                    'kind' => 'SCALAR',
                                    'name' => 'String',
                                    'ofType' => null,
                                ],
                            ],
                        ],
                    ],
                ],
            ),
        ];
    }
}