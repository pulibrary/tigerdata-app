import styles from './Project.module.css';

class ProjectFileAttribute {
  public static selector: string = '.project-file-attribute';
  element: Element;
  name: string;
  value: string | null;

  constructor(element: Element, name: string, value: string | null = null) {
    this.element = element;

    this.name = name;
    this.value = value;
  }

  mutateElement() {
    this.element.textContent = this.value;
  }
}

interface ProjectFile {
  fileName?: string;
  fileSize?: string;
  fileType?: string;
  location?: string;
  creationDate?: string;
  modifiedDate?: string;
  collection?: boolean;
}

interface MediafluxFile {
  name: string;
  type: string;
  path: string;
  size: string;
  created_at?: string;
  created_at_mf?: string;
  last_modified?: string;
  last_modified_mf?: string;
  collection: boolean;
}

class ProjectFileComponent {
  public static elementSelector: string = '.project-file';

  element: Element;
  fileName: string | null;
  fileSize: string | null;
  modifiedDate: string | null;
  fileType: string | null;
  attributes = new Map<string, ProjectFileAttribute>();

  constructor(
    element: Element,
    fileName: string | null = null,
    fileSize: string | null = null,
    modifiedDate: string | null = null,
    fileType: string | null = null,
  ) {
    this.element = element;
    this.element.classList.add(styles.projectFile);

    this.fileName = fileName;
    this.fileSize = fileSize;
    this.modifiedDate = modifiedDate;
    this.fileType = fileType;

    this.bind();
  }

  handleStateChange(event: CustomEvent) {
    for (const [key, attribute] of this.attributes.entries()) {
      if (key in event.detail) {
        attribute.value = event.detail[key];
        attribute.mutateElement();
      }
    }
  }

  bind() {
    this.handleStateChange = this.handleStateChange.bind(this);
    this.element.addEventListener(ProjectComponent.projectStateChange, this.handleStateChange);

    const children = this.element.querySelectorAll(ProjectFileAttribute.selector);
    children.forEach((child) => {
      const attributeName: string | null = child.getAttribute('data-attribute-name');
      if (attributeName) {
        const projectAttribute: ProjectFileAttribute = new ProjectFileAttribute(
          child,
          attributeName,
        );
        this.attributes.set(attributeName, projectAttribute);
      }
    });
  }
}

class ProjectFileTableRow {
  public static elementSelector: string = 'tbody tr';

  state: Map<string, string | null> = new Map<string, string | null>();
  element: Element;

  constructor(element: Element) {
    this.element = element;
    this.element.classList.add(styles.projectFileTableRow);

    this.bind();
  }

  mutateState() {
    const detail: { [key: string]: string | null } = {};
    this.state.forEach((value, key) => {
      detail[key] = value;
    });

    // Ensure that the CustomEvent can bubble up the DOM tree
    // Ensure that preventDefault() can be called on the event
    const stateChangeEvent: CustomEvent = new CustomEvent(ProjectComponent.projectStateChange, {
      detail: detail,
      bubbles: true,
      cancelable: true,
    });
    this.element.dispatchEvent(stateChangeEvent);
  }

  handleClick() {
    this.mutateState();
  }

  bind() {
    const cells = this.element.querySelectorAll('td');
    cells.forEach((cell) => {
      const attributeName: string | null = cell.getAttribute('data-attribute-name');
      const attributeValue: string | null = cell.textContent;
      if (attributeName) {
        this.state.set(attributeName, attributeValue);
      }
    });

    this.handleClick = this.handleClick.bind(this);
    this.element.addEventListener('click', this.handleClick);
    this.mutateState();
  }
}

class ProjectFileTable {
  public static elementSelector: string = 'table#project-contents';
  element: Element;
  rows: ProjectFileTableRow[];

  constructor(element: Element) {
    this.element = element;
    this.rows = [];
    this.bind();
  }

  bind() {
    const elements: NodeListOf<Element> = this.element.querySelectorAll(
      ProjectFileTableRow.elementSelector,
    );

    elements.forEach((element) => {
      const child: ProjectFileTableRow = new ProjectFileTableRow(element);
      this.rows.push(child);
    });

    // If there are any rows, trigger a state change for the first row to initialize the state
    if (this.rows.length > 0) {
      this.rows[0].mutateState();
    }
  }
}

class ProjectComponent {
  public static projectStateChange: string = 'Project.stateChange';
  document: Document;
  file: ProjectFileComponent | null;

  constructor(document: Document) {
    this.document = document;
    this.file = null;
    this.bindChildren();
  }

  public static bind(window: Window) {
    new this(window.document);
  }

  handleStateChange(event: CustomEvent) {
    const stateChangeEvent: CustomEvent = new CustomEvent(ProjectComponent.projectStateChange, {
      detail: event.detail,
      bubbles: false,
      cancelable: true,
    });
    if (!this.file) {
      throw new Error('Project file component not found');
    }
    this.file.element.dispatchEvent(stateChangeEvent);
  }

  bindChildren() {
    const elements: NodeListOf<Element> = this.document.querySelectorAll(
      ProjectFileComponent.elementSelector,
    );

    elements.forEach((element) => {
      this.file = new ProjectFileComponent(element);
    });

    if (this.file) {
      this.handleStateChange = this.handleStateChange.bind(this);
      this.document.addEventListener(
        ProjectComponent.projectStateChange,
        this.handleStateChange,
      );
    }
  }

  public static async dispatchProjectStateChange(
    file: MediafluxFile,
    document: Document = window.document,
  ) {
    const detail: ProjectFile = {
      fileName: file.name,
      fileType: file.type,
      location: file.path,
      fileSize: file.size,
      creationDate: file.created_at || file.created_at_mf,
      modifiedDate: file.last_modified || file.last_modified_mf,
      collection: file.collection,
    };
    const event = new CustomEvent(ProjectComponent.projectStateChange, { detail: detail });
    document.dispatchEvent(event);
  }
}

export {
  MediafluxFile,
  ProjectComponent,
  ProjectFileTable,
  ProjectFileTableRow,
  ProjectFileComponent,
  ProjectFileAttribute,
};
