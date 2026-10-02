import '../models/action_flow.dart';
import '../models/api_definition.dart';
import '../models/app_variable.dart';
import '../models/binding.dart';

const String kProductsResponse = '''
{
  "success": true,
  "data": [
    { "id": 1, "name": "iPhone", "price": 999 },
    { "id": 2, "name": "MacBook", "price": 1999 }
  ]
}''';

const String kLoginResponse = '''
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiJ9.appmaker",
  "user": { "id": 7, "name": "Ada Lovelace", "email": "ada@example.com" }
}''';

const String kUserResponse = '''
{
  "success": true,
  "user": { "id": 7, "name": "Ada Lovelace", "email": "ada@example.com", "role": "admin" }
}''';

const String kCreateOrderResponse = '''
{
  "success": true,
  "order": { "id": "ORD-8842", "status": "pending", "total": 2998 }
}''';

const List<AppVariable> seedVariables = <AppVariable>[
  AppVariable(
    id: 'var_products',
    name: 'products',
    type: VariableType.list,
    elementType: VariableType.object,
    initialValue: '[]',
    description: 'List<Product> returned by Get Products',
  ),
  AppVariable(
    id: 'var_headers',
    name: 'requestHeaders',
    type: VariableType.map,
    initialValue: '{}',
    description: 'Map<String, dynamic> of request headers',
  ),
  AppVariable(
    id: 'var_selected',
    name: 'selectedProduct',
    type: VariableType.object,
    initialValue: 'null',
    description: 'Product currently highlighted by the user',
  ),
  AppVariable(
    id: 'var_loading',
    name: 'isLoading',
    type: VariableType.boolean,
    initialValue: 'false',
    description: 'Controls the loading spinner',
  ),
  AppVariable(
    id: 'var_error',
    name: 'errorMessage',
    type: VariableType.string,
    initialValue: '',
    description: 'Human-readable error shown in a snackbar',
  ),
  AppVariable(
    id: 'var_email',
    name: 'email',
    type: VariableType.string,
    initialValue: '',
  ),
  AppVariable(
    id: 'var_password',
    name: 'password',
    type: VariableType.string,
    initialValue: '',
  ),
  AppVariable(
    id: 'var_token',
    name: 'authToken',
    type: VariableType.string,
    initialValue: '',
  ),
  AppVariable(
    id: 'var_user',
    name: 'currentUser',
    type: VariableType.object,
    initialValue: 'null',
    description: 'User object returned by Login',
  ),
];

const List<ApiDefinition> seedApis = <ApiDefinition>[
  ApiDefinition(
    id: 'api_get_products',
    name: 'Get Products',
    method: HttpMethod.get,
    url: 'https://api.example.com/products',
    headers: <KeyValuePair>[
      KeyValuePair(
        id: 'h_auth',
        key: 'Authorization',
        value: 'Bearer {{authToken}}',
      ),
    ],
    query: <KeyValuePair>[
      KeyValuePair(id: 'q_category', key: 'category', value: '{{selectedCategory}}'),
      KeyValuePair(id: 'q_page', key: 'page', value: '{{page}}'),
    ],
    responseJson: kProductsResponse,
  ),
  ApiDefinition(
    id: 'api_login',
    name: 'Login',
    method: HttpMethod.post,
    url: 'https://api.example.com/auth/login',
    headers: <KeyValuePair>[
      KeyValuePair(id: 'h_json', key: 'Content-Type', value: 'application/json'),
    ],
    body: '{\n  "email": "{{email}}",\n  "password": "{{password}}"\n}',
    responseJson: kLoginResponse,
  ),
  ApiDefinition(
    id: 'api_get_user',
    name: 'Get User',
    method: HttpMethod.get,
    url: 'https://api.example.com/user/{{currentUser.id}}',
    responseJson: kUserResponse,
  ),
  ApiDefinition(
    id: 'api_create_order',
    name: 'Create Order',
    method: HttpMethod.post,
    url: 'https://api.example.com/orders',
    body: '{\n  "userId": "{{currentUser.id}}",\n  "items": {{cart}}\n}',
    responseJson: kCreateOrderResponse,
  ),
];

const List<ActionFlow> seedFlows = <ActionFlow>[
  ActionFlow(
    id: 'flow_load_products',
    name: 'Load Products',
    trigger: FlowTrigger.onTap,
    description: 'Button: "Load Products"',
    steps: <FlowStep>[
      FlowStep(
        id: 's1',
        kind: StepKind.setVariable,
        variableId: 'isLoading',
        expression: 'true',
      ),
      FlowStep(
        id: 's2',
        kind: StepKind.callApi,
        label: 'Get Products',
        apiId: 'api_get_products',
        onSuccess: <FlowStep>[
          FlowStep(
            id: 's2a',
            kind: StepKind.setVariable,
            variableId: 'products',
            expression: 'response.data',
          ),
          FlowStep(
            id: 's2b',
            kind: StepKind.setVariable,
            variableId: 'isLoading',
            expression: 'false',
          ),
          FlowStep(
            id: 's2c',
            kind: StepKind.navigate,
            target: 'Refresh UI',
          ),
        ],
        onError: <FlowStep>[
          FlowStep(
            id: 's2d',
            kind: StepKind.setVariable,
            variableId: 'errorMessage',
            expression: 'response.message',
          ),
          FlowStep(
            id: 's2e',
            kind: StepKind.showMessage,
            expression: 'errorMessage',
          ),
        ],
      ),
    ],
  ),
  ActionFlow(
    id: 'flow_login',
    name: 'Login',
    trigger: FlowTrigger.onTap,
    description: 'Login Button',
    steps: <FlowStep>[
      FlowStep(
        id: 'l1',
        kind: StepKind.setVariable,
        variableId: 'isLoading',
        expression: 'true',
      ),
      FlowStep(
        id: 'l2',
        kind: StepKind.callApi,
        label: 'Login',
        apiId: 'api_login',
        onSuccess: <FlowStep>[
          FlowStep(
            id: 'l2a',
            kind: StepKind.setVariable,
            variableId: 'authToken',
            expression: 'response.token',
          ),
          FlowStep(
            id: 'l2b',
            kind: StepKind.setVariable,
            variableId: 'currentUser',
            expression: 'response.user',
          ),
          FlowStep(
            id: 'l2c',
            kind: StepKind.navigate,
            target: 'Home',
          ),
        ],
        onError: <FlowStep>[
          FlowStep(
            id: 'l2d',
            kind: StepKind.setVariable,
            variableId: 'errorMessage',
            expression: 'response.message',
          ),
          FlowStep(
            id: 'l2e',
            kind: StepKind.showMessage,
            expression: 'errorMessage',
          ),
        ],
      ),
    ],
  ),
];

const List<WidgetBinding> seedBindings = <WidgetBinding>[
  WidgetBinding(
    id: 'bind_products',
    widgetName: 'Products ListView',
    kind: WidgetKind.listView,
    sourceVariableId: 'var_products',
    itemLabel: 'product',
    fields: <BindingField>[
      BindingField(label: 'Product name', expression: 'product.name'),
      BindingField(label: 'Product price', expression: 'product.price'),
    ],
  ),
  WidgetBinding(
    id: 'bind_login',
    widgetName: 'Login Form',
    kind: WidgetKind.form,
    fields: <BindingField>[
      BindingField(label: 'Email input', expression: 'email'),
      BindingField(label: 'Password input', expression: 'password'),
    ],
  ),
  WidgetBinding(
    id: 'bind_loading',
    widgetName: 'Loading Indicator',
    kind: WidgetKind.text,
    sourceVariableId: 'var_loading',
    fields: <BindingField>[
      BindingField(label: 'Visibility', expression: 'isLoading'),
    ],
  ),
];
