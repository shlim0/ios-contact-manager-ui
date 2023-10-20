import UIKit
final class ContactViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!
    private var contactDTOs: [ContactDTO] = []
    private var filteredContact: [ContactDTO] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadJSON()
        loadDelegate()
    }
    
    @available(iOS 16.0, *)
    @IBAction private func touchUpAddButton(_ sender: Any) {
        guard let newContactViewController
                = self.storyboard?.instantiateViewController(identifier: "NewContactViewController")
                as? NewContactViewController else {
            return
        }
        newContactViewController.delegate = self
        present(newContactViewController, animated: true)
    }
    
    private func loadJSON() {
        do {
            if let dummyContactDTOs = try decodeJSON() {
                contactDTOs = dummyContactDTOs
            }
        }
        catch {
            let alertController = UIAlertController()
            alertController
                .configureAlertController(title: "데이터 불러오기 실패",
                                          message: nil,
                                          defaultAction: "예",
                                          destructiveAction: nil,
                                          viewController: self)
        }
    }
    
    private func loadDelegate() {
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
}

extension ContactViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !filteredContact.isEmpty {
            return filteredContact.count
        } else {
            return contactDTOs.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: CustomTableViewCell
                = tableView.dequeueReusableCell(withIdentifier: CustomTableViewCell.customCellIdentifier, for: indexPath) as? CustomTableViewCell else { return UITableViewCell() }
        
        let contact = filteredContact.isEmpty ? contactDTOs[indexPath.row] : filteredContact[indexPath.row]
        cell.configure(with: contact)
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        guard !filteredContact.isEmpty else {
            contactDTOs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            return
        }
        
        let contact = filteredContact.remove(at: indexPath.row)
        contactDTOs = contactDTOs.filter { $0.name != contact.name }
        
        if !filteredContact.isEmpty {
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else {
            searchBar.text = ""
            tableView.reloadData()
        }
    }
}

extension ContactViewController: DataSendable {
    func send(_ data: ContactDTO) {
        contactDTOs.append(data)
        let indexPath = IndexPath(row: self.contactDTOs.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
    }
}

extension ContactViewController: JSONCodable { }

extension ContactViewController: UITableViewDelegate { }

extension ContactViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredContact = contactDTOs.filter({
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.phoneNumber.localizedCaseInsensitiveContains(searchText)
        })
        
        tableView.reloadData()
    }
}
